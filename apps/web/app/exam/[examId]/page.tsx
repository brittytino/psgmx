"use client";

import { use, useEffect, useState, useRef } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { AlertCircle, Camera, CheckCircle2, ChevronLeft, ChevronRight, Clock, VideoOff, Flag } from "lucide-react";

type Question = {
  id: string;
  question_text: string;
  option_a: string | null;
  option_b: string | null;
  option_c: string | null;
  option_d: string | null;
  marks: number;
};

type ProctoringFlag = {
  type: string;
  timestamp: string;
};

// Seeded RNG
function seedrandom(seedStr: string) {
  let h = 0xdeadbeef;
  for(let i = 0; i < seedStr.length; i++) {
    h = Math.imul(h ^ seedStr.charCodeAt(i), 2654435761);
  }
  return function() {
    h = Math.imul(h ^ (h >>> 16), 2246822507);
    h = Math.imul(h ^ (h >>> 13), 3266489909);
    return (h ^= h >>> 16) >>> 0;
  }
}

function shuffle(array: any[], seedStr: string) {
  const arr = [...array];
  const rng = seedrandom(seedStr);
  let currentIndex = arr.length, randomIndex;
  while (currentIndex != 0) {
    randomIndex = rng() % currentIndex;
    currentIndex--;
    [arr[currentIndex], arr[randomIndex]] = [
      arr[randomIndex], arr[currentIndex]];
  }
  return arr;
}

export default function ExamPage({ params }: { params: Promise<{ examId: string }> }) {
  const resolvedParams = use(params);
  const examId = resolvedParams.examId;
  const router = useRouter();
  const supabase = createClient();

  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [exam, setExam] = useState<any>(null);
  const [questions, setQuestions] = useState<Question[]>([]);
  const [answers, setAnswers] = useState<Record<string, string>>({});
  const [currentIndex, setCurrentIndex] = useState(0);
  const [userId, setUserId] = useState<string | null>(null);
  
  // Proctoring
  const [cameraActive, setCameraActive] = useState(false);
  const [cameraError, setCameraError] = useState("");
  const videoRef = useRef<HTMLVideoElement>(null);
  const [flags, setFlags] = useState<ProctoringFlag[]>([]);
  const startTime = useRef(Date.now());
  const [timeLeft, setTimeLeft] = useState<number>(0);
  const [warnings, setWarnings] = useState<string[]>([]);

  useEffect(() => {
    async function loadData() {
      const { data: authData } = await supabase.auth.getUser();
      if (!authData.user) {
        router.push("/login");
        return;
      }
      setUserId(authData.user.id);

      // Check if already submitted
      const { data: existing } = await supabase
        .from('mock_exam_results')
        .select('id')
        .eq('exam_id', examId)
        .eq('student_id', authData.user.id)
        .maybeSingle();

      if (existing) {
        alert("You have already submitted this exam.");
        router.push("/");
        return;
      }

      const { data: examData } = await supabase
        .from("mock_exams")
        .select("*")
        .eq("id", examId)
        .maybeSingle();
      
      if (!examData) {
        alert("Exam not found");
        router.push("/");
        return;
      }

      const { data: qData } = await supabase
        .from("mock_exam_questions")
        .select("id, question_text, option_a, option_b, option_c, option_d, marks")
        .eq("exam_id", examId)
        .order("order_index", { ascending: true });

      setExam(examData);
      
      if (qData) {
        // Deterministic shuffle based on student ID and exam ID
        const seed = `${authData.user.id}-${examId}`;
        const shuffled = shuffle(qData, seed);
        setQuestions(shuffled);
      }
      
      setTimeLeft(examData.duration_minutes * 60);
      setLoading(false);
    }
    loadData();
  }, [examId]);

  // Request Camera
  useEffect(() => {
    let stream: MediaStream | null = null;
    if (!loading) {
      navigator.mediaDevices.getUserMedia({ video: true, audio: false })
        .then((s) => {
          stream = s;
          setCameraActive(true);
          setCameraError("");
          if (videoRef.current) {
            videoRef.current.srcObject = s;
          }
        })
        .catch((e) => {
          setCameraActive(false);
          setCameraError("Camera access required for proctoring.");
          addFlag("camera_loss");
        });
    }
    return () => {
      if (stream) {
        stream.getTracks().forEach(t => t.stop());
      }
    };
  }, [loading]);

  // Tab switch detection
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.visibilityState === 'hidden') {
        addFlag("tab_switch");
        setWarnings(w => [...w, "Tab switch detected! This has been recorded."]);
        setTimeout(() => {
          setWarnings(w => w.slice(1));
        }, 5000);
      }
    };

    const handleBlur = () => {
      addFlag("window_blur");
    };

    window.addEventListener("visibilitychange", handleVisibilityChange);
    window.addEventListener("blur", handleBlur);

    return () => {
      window.removeEventListener("visibilitychange", handleVisibilityChange);
      window.removeEventListener("blur", handleBlur);
    };
  }, []);

  // Timer
  useEffect(() => {
    if (loading || timeLeft <= 0) return;
    const timerId = setInterval(() => {
      setTimeLeft(t => {
        if (t <= 1) {
          clearInterval(timerId);
          handleSubmit();
          return 0;
        }
        return t - 1;
      });
    }, 1000);
    return () => clearInterval(timerId);
  }, [loading, timeLeft]);

  const addFlag = (type: string) => {
    setFlags(f => [...f, { type, timestamp: new Date().toISOString() }]);
  };

  const handleSelect = (qId: string, option: string) => {
    setAnswers(prev => ({ ...prev, [qId]: option }));
  };

  const handleSubmit = async () => {
    if (!userId || !exam) return;
    setSubmitting(true);
    
    const timeTaken = Math.floor((Date.now() - startTime.current) / 1000);

    // Evaluate answers
    let rawMarks = 0;
    
    // We fetch correct options now to prevent client side leaking
    const { data: fullQuestions } = await supabase
        .from("mock_exam_questions")
        .select("id, correct_option, marks")
        .eq("exam_id", examId);

    if (fullQuestions) {
      for (const q of fullQuestions) {
        if (answers[q.id] && answers[q.id].toLowerCase() === q.correct_option?.toLowerCase()) {
          rawMarks += q.marks;
        }
      }
    }

    const maxMarks = exam.total_marks || 100;
    const normalizedScore = (rawMarks / maxMarks) * 100;

    await supabase.from("mock_exam_results").insert({
      exam_id: examId,
      student_id: userId,
      raw_marks: rawMarks,
      score: normalizedScore,
      time_taken_seconds: timeTaken,
      proctoring_flags: flags
    });

    alert("Exam submitted successfully!");
    router.push("/");
  };

  if (loading) {
    return <div className="min-h-screen flex items-center justify-center bg-gray-50"><span className="loader"></span></div>;
  }

  if (cameraError) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 p-4">
        <div className="bg-white p-8 rounded-2xl shadow-xl max-w-md w-full text-center">
          <div className="w-16 h-16 bg-red-100 text-red-600 rounded-full flex items-center justify-center mx-auto mb-4">
            <VideoOff size={32} />
          </div>
          <h2 className="text-xl font-bold mb-2">Camera Required</h2>
          <p className="text-gray-600 mb-6">{cameraError}</p>
          <button 
            onClick={() => window.location.reload()}
            className="w-full py-3 px-4 bg-indigo-600 text-white rounded-xl font-medium hover:bg-indigo-700 transition"
          >
            Grant Permission and Reload
          </button>
        </div>
      </div>
    );
  }

  const currentQ = questions[currentIndex];
  
  const formatTime = (sec: number) => {
    const h = Math.floor(sec / 3600);
    const m = Math.floor((sec % 3600) / 60);
    const s = sec % 60;
    return `${h > 0 ? h+':' : ''}${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between sticky top-0 z-50">
        <div>
          <h1 className="text-lg font-bold text-gray-900">{exam?.title}</h1>
          <p className="text-sm text-gray-500">{questions.length} Questions • {exam?.total_marks} Marks</p>
        </div>
        <div className="flex items-center gap-6">
          <div className="flex items-center gap-2 text-indigo-600 font-medium bg-indigo-50 px-4 py-2 rounded-lg">
            <Clock size={18} />
            <span>{formatTime(timeLeft)}</span>
          </div>
          <button
            onClick={() => {
              if (window.confirm("Are you sure you want to submit the exam?")) {
                handleSubmit();
              }
            }}
            disabled={submitting}
            className="bg-indigo-600 hover:bg-indigo-700 text-white px-6 py-2 rounded-lg font-medium transition disabled:opacity-50"
          >
            {submitting ? "Submitting..." : "Submit Exam"}
          </button>
        </div>
      </header>

      {/* Warnings Toast */}
      {warnings.length > 0 && (
        <div className="fixed top-24 left-1/2 -translate-x-1/2 z-50 flex flex-col gap-2">
          {warnings.map((w, i) => (
            <div key={i} className="bg-red-500 text-white px-6 py-3 rounded-lg shadow-lg flex items-center gap-2">
              <AlertCircle size={18} />
              <span className="font-medium">{w}</span>
            </div>
          ))}
        </div>
      )}

      <div className="flex-1 flex w-full max-w-7xl mx-auto p-6 gap-6">
        {/* Main Content */}
        <div className="flex-1 flex flex-col">
          <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-8 flex-1">
            <div className="flex items-center justify-between mb-8">
              <span className="text-sm font-semibold text-gray-500 uppercase tracking-wider">
                Question {currentIndex + 1} of {questions.length}
              </span>
              <span className="text-sm font-medium text-gray-500 bg-gray-100 px-3 py-1 rounded-full">
                {currentQ?.marks} Marks
              </span>
            </div>

            <h2 className="text-xl text-gray-900 font-medium leading-relaxed mb-8">
              {currentQ?.question_text}
            </h2>

            <div className="space-y-4">
              {['A', 'B', 'C', 'D'].map(opt => {
                const optKey = `option_${opt.toLowerCase()}` as keyof Question;
                const optText = currentQ?.[optKey];
                if (!optText) return null;
                
                const isSelected = answers[currentQ.id] === opt;
                
                return (
                  <button
                    key={opt}
                    onClick={() => handleSelect(currentQ.id, opt)}
                    className={`w-full text-left p-4 rounded-xl border-2 transition-all duration-200 flex items-start gap-4 ${
                      isSelected 
                        ? 'border-indigo-600 bg-indigo-50' 
                        : 'border-gray-200 hover:border-gray-300 hover:bg-gray-50'
                    }`}
                  >
                    <div className={`w-6 h-6 rounded-full border-2 flex items-center justify-center mt-0.5 shrink-0 ${
                      isSelected ? 'border-indigo-600 bg-indigo-600' : 'border-gray-300'
                    }`}>
                      {isSelected && <div className="w-2 h-2 rounded-full bg-white" />}
                    </div>
                    <span className={`text-base ${isSelected ? 'text-indigo-900 font-medium' : 'text-gray-700'}`}>
                      <span className="font-semibold mr-2">{opt}.</span> {optText}
                    </span>
                  </button>
                );
              })}
            </div>
          </div>

          <div className="flex items-center justify-between mt-6">
            <button
              onClick={() => setCurrentIndex(i => Math.max(0, i - 1))}
              disabled={currentIndex === 0}
              className="flex items-center gap-2 px-6 py-3 rounded-xl border border-gray-200 bg-white text-gray-700 font-medium hover:bg-gray-50 disabled:opacity-50 transition"
            >
              <ChevronLeft size={20} />
              Previous
            </button>
            <button
              onClick={() => setCurrentIndex(i => Math.min(questions.length - 1, i + 1))}
              disabled={currentIndex === questions.length - 1}
              className="flex items-center gap-2 px-6 py-3 rounded-xl bg-gray-900 text-white font-medium hover:bg-gray-800 disabled:opacity-50 transition"
            >
              Next
              <ChevronRight size={20} />
            </button>
          </div>
        </div>

        {/* Sidebar */}
        <div className="w-80 flex flex-col gap-6 shrink-0">
          {/* Proctoring Camera */}
          <div className="bg-white rounded-2xl shadow-sm border border-gray-200 overflow-hidden">
            <div className="bg-gray-900 p-3 flex items-center justify-between">
              <div className="flex items-center gap-2 text-white">
                <Camera size={16} />
                <span className="text-sm font-medium">Proctoring Active</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-2 h-2 rounded-full bg-red-500 animate-pulse" />
                <span className="text-xs font-medium text-red-400">REC</span>
              </div>
            </div>
            <div className="aspect-video bg-gray-800 relative">
              <video
                ref={videoRef}
                autoPlay
                playsInline
                muted
                className="w-full h-full object-cover transform -scale-x-100"
              />
            </div>
            {flags.length > 0 && (
              <div className="p-3 bg-red-50 border-t border-red-100 flex items-start gap-2 text-red-700 text-xs font-medium">
                <Flag size={14} className="shrink-0 mt-0.5" />
                <span>{flags.length} violations detected</span>
              </div>
            )}
          </div>

          {/* Question Navigator */}
          <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-6 flex-1">
            <h3 className="text-sm font-bold text-gray-900 mb-4 uppercase tracking-wider">Question Navigator</h3>
            <div className="grid grid-cols-5 gap-2">
              {questions.map((q, i) => {
                const isAnswered = !!answers[q.id];
                const isCurrent = i === currentIndex;
                return (
                  <button
                    key={q.id}
                    onClick={() => setCurrentIndex(i)}
                    className={`w-10 h-10 rounded-lg text-sm font-medium flex items-center justify-center transition-all ${
                      isCurrent 
                        ? 'ring-2 ring-indigo-600 ring-offset-2 bg-indigo-600 text-white' 
                        : isAnswered 
                          ? 'bg-indigo-50 text-indigo-700 border border-indigo-200' 
                          : 'bg-gray-50 text-gray-500 border border-gray-200 hover:border-gray-300'
                    }`}
                  >
                    {i + 1}
                  </button>
                );
              })}
            </div>
            <div className="mt-8 flex items-center justify-between text-sm text-gray-500">
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded bg-indigo-50 border border-indigo-200" />
                <span>Answered ({Object.keys(answers).length})</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded bg-gray-50 border border-gray-200" />
                <span>Unanswered ({questions.length - Object.keys(answers).length})</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
