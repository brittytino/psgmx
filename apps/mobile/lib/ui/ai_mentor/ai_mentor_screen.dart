import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../widgets/rive_placeholder.dart';
import '../../services/ai_mentor_service.dart';

class AiMentorScreen extends StatefulWidget {
  const AiMentorScreen({super.key});

  @override
  State<AiMentorScreen> createState() => _AiMentorScreenState();
}

class _Message {
  final String content;
  final bool isUser;
  final String time;

  _Message(this.content, this.isUser, this.time);
}

class _AiMentorScreenState extends State<AiMentorScreen> {
  final _service = AiMentorService();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<_Message> _messages = [];
  bool _isLoading = false;

  Timer? _thinkingTimer;
  int _thinkingStepIndex = 0;

  static const List<String> _thinkingSteps = [
    'Thinking...',
    'Grinding...',
    'Looking RAG model...',
    'Synthesizing response...',
    'Polishing advice...',
  ];

  static const List<String> _simpleGreetingReplies = [
    "Hi there! I'm Spark, your AI placement mentor. How can I guide your preparation today?",
    "Hello! Ready to sharpen your skills or work on your placement prep? I'm right here with you!",
    "Hey! Great to see you. What topic are we tackling today—DSA, Aptitude, Mock Interviews, or Resume tips?",
    "Good day! Ask me anything about placements, mock interviews, or tech skills—I'm here to help.",
    "Hi! I'm excited to assist you on your tech journey. What's on your mind today?",
    "Hello! Step by step, problem by problem—we're making progress. How can I help you today?",
  ];

  // 10 distinct, mature companion replies per topic to ensure non-repetition per user.
  static const Map<String, List<String>> _predefinedReplyPools = {
    'dsa_study_plan': [
      "Here's my realistic roadmap for you: Start with **Arrays & Strings** to build confidence, then master **Hash Maps and Two Pointers**. Spend 2 weeks on **Trees and Graphs**—they are interview gold. Solve 2 problems daily, explain your logic out loud, and don't rush into solutions. I'm right here with you on this journey.",
      "Building DSA mastery is like endurance training. Focus on pattern recognition rather than memorizing code: **Sliding Window**, **Fast/Slow Pointers**, **BFS/DFS**, and **Dynamic Programming** fundamentals. Consistent daily practice beats weekend sprees every single time. Take it step by step!",
      "If I were sitting next to you planning this out, I'd say: spend 70% of your time on **Medium-level problems**. Master time and space complexity analysis—interviewers care just as much about how you think as your final code. Keep pushing, you're growing every day.",
      "Let's structure your week:\n- **Mon/Tue**: Linked Lists & Stacks\n- **Wed/Thu**: Recursion & Binary Search\n- **Fri**: Binary Trees\n- **Weekends**: Revision & Weak Spots\n\nRemember, feeling stuck is part of the process. Take a breath and debug step-by-step.",
      "My top advice for DSA: Never jump straight into code. Spend 5 minutes drawing test cases on paper, identify edge cases (**empty array, negative numbers, single element**), and outline your pseudo-code first. You've got the logic inside you—trust the process.",
      "Think of DSA as learning chess patterns. Start with basic data structures, then tackle Graph traversals and Dynamic Programming subproblems. Solve 1 Easy + 1 Medium daily. Track your mistakes in a journal—that's where true growth happens.",
      "Don't let intimidating problem statements throw you off. Break complex problems into smaller sub-problems:\n1. **What is the input/output?**\n2. **Can I solve a smaller sub-case?**\n3. **How can I optimize?**\n\nYou're far more capable than you realize!",
      "For top-tier company interviews, focus heavily on LeetCode patterns: **Two Pointers**, **Top K Elements**, **Binary Search variations**, and **Backtracking**. Quality over quantity always wins.",
      "Patience is your secret weapon here. When a problem takes an hour, don't feel discouraged—that's your brain forming new synaptic connections! Review optimal solutions, write down the key insight, and try re-solving it 3 days later.",
      "Here is your 30-day DSA blueprint:\n- **Days 1–10**: Arrays, Strings, Stacks, Queues\n- **Days 11–20**: Sorting, Binary Search, HashMaps\n- **Days 21–30**: Trees, Graphs, Dynamic Programming\n\nStay disciplined, stay curious—I believe in you!",
    ],
    'aptitude_prep_tips': [
      "Aptitude isn't about raw math skills—it's about **speed and pattern recognition**. Practice short tricks for **Percentages, Ratios, and Time & Work**. Set a timer for 1 minute per question to simulate actual exam pressure. You've got this!",
      "When tackling quantitative aptitude, start by scanning the entire section. Answer high-confidence questions first (**Data Interpretation, Series, Simplification**), then move to word problems. Time management is 80% of your success.",
      "Logical reasoning is like solving daily puzzles. Pay special attention to **Blood Relations, Syllogisms, and Seating Arrangements**—they carry high marks. Draw clean diagrams on scratch paper to avoid silly mistakes.",
      "Verbal aptitude often trips candidates up. Read technical articles or editorial pieces daily to improve comprehension speed. Practice elimination strategies for Multiple Choice Questions—finding why 3 options are wrong is often easier than proving 1 right.",
      "Here's a golden rule for aptitude tests: **Never spend more than 90 seconds on a single question in round one**. Mark it, move on, and return if time permits. Preserving your momentum and mental energy is key!",
      "Work on mental math daily! Practice multiplying 2-digit numbers, memorizing squares up to 30 and cubes up to 20, and converting fractions to percentages instantly. Small speed gains accumulate into huge advantages.",
      "Data Interpretation (DI) can look overwhelming with large tables and charts. Tip: **Look at the options before calculating!** Often, rough estimation is enough to eliminate 3 options without doing tedious calculations.",
      "Consistency is key for aptitude. Spend 30 minutes every morning on 15 timed questions. Review every mistake immediately. Within two weeks, your speed and accuracy will double. Keep up the great work!",
      "For **Permutations, Combinations, and Probability**: focus on fundamental principles. Ask yourself *'Does order matter?'* (Permutation vs Combination). Once the core formula is clear, the problem solves itself.",
      "Remember to keep your mind calm during test day. When faced with a tricky puzzle, take a slow 3-second breath, break down the given facts logically, and trust your preparation. You are ready for this!",
    ],
    'mock_interview_tips': [
      "In technical interviews, your thought process matters as much as your code! Speak out loud continuously. Say: *'First, I'm thinking of a brute force approach with O(N^2) complexity, but we can optimize it using a HashMap to O(N).'* Interviewers love clear communicators.",
      "For HR and behavioral questions, master the **STAR method**: **Situation, Task, Action, Result**. Quantify your results whenever possible (e.g., *'improved performance by 35%'*). It turns generic answers into compelling stories.",
      "If you don't know the exact answer to a technical question, don't panic or guess blindly! State what you **do know** around the topic, explain how you would find out or debug it, and show your enthusiasm to learn. Honesty creates deep trust.",
      "Body language & tone in virtual interviews: Maintain eye contact with the camera, sit up straight, nod when listening, and speak with structured warmth. **Confidence is contagious.**",
      "Always have 2–3 thoughtful questions prepared for the interviewer at the end. Ask about their **tech stack evolution**, **team engineering culture**, or **upcoming challenges**. It demonstrates genuine interest and professionalism.",
      "Before your interview, review your resume thoroughly! Every project, library, and metric mentioned on your resume is fair game. Be ready to explain your architecture decisions, challenges faced, and how you resolved them.",
      "When asked *'Tell me about yourself'*, keep it crisp (90 seconds):\n1. **Current background & passion**\n2. **Key technical projects & skills**\n3. **Why you're excited about this specific role**\n\nMake it memorable!",
      "For **System Design or Object-Oriented Design** questions: Start by clarifying functional and non-functional requirements! Never start drawing architecture until constraints (scale, latency, storage) are defined.",
      "Treat mock interviews as safe experiments. The more you practice speaking out loud, the more natural and relaxed you'll feel during the real placement drive. I'm right here cheering you on!",
      "Remember: Interviewers are looking for potential colleagues they'd enjoy working with. Show curiosity, stay positive when given hints, and treat the interview as a collaborative problem-solving session.",
    ],
    'top_companies': [
      "Product-based giants (**MAANG, Uber, Atlassian**) focus heavily on core **DSA, System Design, and CS Fundamentals (OS, DBMS, CN)**. Prepare for multi-round coding evaluations and deep dive architecture discussions.",
      "Service-based leaders (**TCS Digital, Infosys Power Programmer, Wipro Turbo**) evaluate strong aptitude, core programming skills (**Java/Python/C++**), clean logic, and solid communication. Focus on speed & accuracy in early rounds.",
      "Fast-growing tech startups (**Unicorns & Series B+**) value practical build experience! Highlight your **full-stack projects, API integrations, database design**, and hands-on GitHub repositories.",
      "When targeting tier-1 companies, customize your prep: research their specific interview patterns on LeetCode company tags and GeeksforGeeks placement experiences. Tailored practice yields maximum results.",
      "Don't overlook mid-sized product companies and specialized tech consultancies—they offer incredible mentorship, competitive packages, rapid career growth, and heavy hands-on engineering exposure early on.",
      "To stand out for competitive off-campus drives: build **2 high-quality, end-to-end deployed projects** with clean code, documentation, and live demo links. A working product speaks louder than a 2-page resume!",
      "Company research tip: Before any company drive, read their recent engineering blogs, press releases, or tech stack updates. Referencing their real tech challenges in your interview will set you apart from 99% of candidates.",
      "System fundamentals (**Operating Systems, Database Normalization, Computer Networks, OOPs concepts**) are heavily tested in written rounds for top companies. Review standard 100 GFG technical MCQs.",
      "Maintain a spreadsheet of companies you're applying to: role, application date, status, referral contacts, and interview stages. Structured organization reduces job-hunting stress tremendously.",
      "Regardless of company tier, remember that every interview is valuable practice. Stay resilient, keep refining your skills, and your dream offer will follow. You've got what it takes!",
    ],
    'default': [
      "I'm right here with you on this journey. Placement prep can feel overwhelming at times, but taking it **one day at a time, one problem at a time**, builds unstoppable momentum. What specific area shall we conquer today?",
      "Growth happens in quiet, consistent moments. Even when progress feels slow, every line of code you write and every problem you solve is preparing you for success. Keep believing in yourself!",
      "As your AI companion, my goal is to help you unlock your full potential. Remember to balance intense study with proper rest, good sleep, and healthy breaks. A refreshed mind solves problems twice as fast.",
      "Never compare your chapter 1 to someone else's chapter 20. Your journey is unique, and your dedication will pay off. Let's focus on making today 1% better than yesterday.",
      "Engineering excellence is a habit, not a destination. Focus on mastering core concepts deeply rather than rushing through topics. I'm always here whenever you need advice, clarity, or encouragement.",
      "When you feel stuck, step back for 5 minutes, take a walk or drink water, then look at the problem with fresh eyes. Often, the breakthrough happens right after a short mental break!",
      "You have already come so far in your MCA journey. Trust the foundation you've built, stay disciplined with your daily routine, and keep your goals clear. Great things are coming your way.",
      "Small daily wins compound into massive career milestones. Celebrate solving that tricky problem today, fixing that stubborn bug, or completing your daily revision. I'm proud of your effort!",
      "Preparation meets opportunity when you stay consistent. Keep sharpening your technical toolkit, polishing your communication, and refining your resume. You're building a bright future.",
      "I'm honored to be your mentor and companion. Whenever you face doubts, remember why you started. Together, we'll turn your placement goals into reality. What's on your mind next?",
    ],
  };

  @override
  void initState() {
    super.initState();
    _messages.add(_Message(
      "Your AI mentor. Ask me anything about placements, skills, prep, or your journey — I'm here!",
      false,
      _getCurrentTime(),
    ));
  }

  @override
  void dispose() {
    _thinkingTimer?.cancel();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _startThinkingAnimation() {
    _thinkingStepIndex = 0;
    _thinkingTimer?.cancel();
    _thinkingTimer = Timer.periodic(const Duration(milliseconds: 850), (timer) {
      if (mounted && _isLoading) {
        setState(() {
          _thinkingStepIndex = (_thinkingStepIndex + 1) % _thinkingSteps.length;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _stopThinkingAnimation() {
    _thinkingTimer?.cancel();
    _thinkingTimer = null;
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    int hour = now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;

    return '$hour:$minute $period';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(_Message(
        "Chat reset! How can I guide you today?",
        false,
        _getCurrentTime(),
      ));
    });
  }

  bool _isSimpleGreeting(String message) {
    final clean = message.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '');
    const greetings = [
      'hi', 'hello', 'hey', 'heya', 'howdy', 'good morning', 'good afternoon',
      'good evening', 'namaste', 'sup', 'hi spark', 'hello spark', 'hey spark',
      'who are you', 'what can you do', 'help', 'thanks', 'thank you'
    ];
    if (greetings.contains(clean)) return true;
    if (clean.length <= 4 && (clean.startsWith('hi') || clean.startsWith('hey'))) return true;
    return false;
  }

  /// Gets a mature companion response for predefined questions.
  /// Stores used indices in SharedPreferences to guarantee no immediate repetition for the same user.
  Future<String?> _getPredefinedNonRepeatingReply(String prompt) async {
    final normalizedKey = prompt.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final poolKey = _predefinedReplyPools.containsKey(normalizedKey) ? normalizedKey : 'default';
    final replies = _predefinedReplyPools[poolKey]!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = 'ai_mentor_used_replies_$poolKey';

      List<String> usedStr = prefs.getStringList(storageKey) ?? [];
      List<int> usedIndices = usedStr.map((e) => int.tryParse(e) ?? -1).where((i) => i >= 0 && i < replies.length).toList();

      if (usedIndices.length >= replies.length) {
        usedIndices.clear();
      }

      List<int> availableIndices = [];
      for (int i = 0; i < replies.length; i++) {
        if (!usedIndices.contains(i)) {
          availableIndices.add(i);
        }
      }

      if (availableIndices.isEmpty) {
        availableIndices = List.generate(replies.length, (i) => i);
      }

      final random = Random();
      final selectedIndex = availableIndices[random.nextInt(availableIndices.length)];

      usedIndices.add(selectedIndex);
      await prefs.setStringList(storageKey, usedIndices.map((e) => e.toString()).toList());

      return replies[selectedIndex];
    } catch (e) {
      final random = Random();
      return replies[random.nextInt(replies.length)];
    }
  }

  Future<void> _sendMessage(String text, {bool isPredefined = false}) async {
    final messageText = text.trim();
    if (messageText.isEmpty) return;

    _textCtrl.clear();

    // Check if simple greeting for instant response
    if (_isSimpleGreeting(messageText)) {
      final random = Random();
      final instantReply = _simpleGreetingReplies[random.nextInt(_simpleGreetingReplies.length)];
      setState(() {
        _messages.add(_Message(messageText, true, _getCurrentTime()));
        _messages.add(_Message(instantReply, false, _getCurrentTime()));
      });
      _scrollToBottom();
      return;
    }

    setState(() {
      _messages.add(_Message(messageText, true, _getCurrentTime()));
      _isLoading = true;
    });
    _startThinkingAnimation();
    _scrollToBottom();

    try {
      String? reply;

      final normalized = messageText.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      final isKnownPredefined = isPredefined || _predefinedReplyPools.containsKey(normalized);

      if (isKnownPredefined) {
        // Fast response for pre-defined questions
        reply = await _getPredefinedNonRepeatingReply(messageText);
      } else {
        final history = _messages.map((m) => {
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.content,
        }).toList();

        reply = await _service.sendMockInterviewMessage(
          message: messageText,
          history: history,
          isResumeFeedback: false,
        );
      }

      if (mounted) {
        _stopThinkingAnimation();
        setState(() {
          _messages.add(_Message(
            reply ?? 'I am here with you. Let\'s try asking that again in a slightly different way!',
            false,
            _getCurrentTime(),
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        _stopThinkingAnimation();
        setState(() {
          _messages.add(_Message('Error connecting to AI. Please try again.', false, _getCurrentTime()));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar with Top-Left Back Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
              child: Row(
                children: [
                  // Back Button in Top-Left Corner
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.maybePop(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          LucideIcons.arrowLeft,
                          size: 18,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Header Title & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'AI Mentor',
                              style: GoogleFonts.sora(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.illusGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.sparkles, color: AppTheme.illusGold, size: 10),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Spark',
                                    style: GoogleFonts.inter(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.illusGold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your companion for placements & tech growth',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Reset / Clear Chat Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _clearChat,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.rotateCcw, size: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text(
                              'Reset',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5),

            // Chat Messages Area
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: msg.isUser
                        ? _buildUserBubble(msg)
                        : _buildAiBubble(msg, isFirst: index == 0),
                  );
                },
              ),
            ),

            // Claude-Style Dynamic Thinking Animation
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildThinkingWidget(theme),
                ),
              ),

            // Predefined Quick Action Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Row(
                children: [
                  _buildPromptChip(LucideIcons.code, 'DSA Study Plan'),
                  const SizedBox(width: 8),
                  _buildPromptChip(LucideIcons.target, 'Aptitude Prep Tips'),
                  const SizedBox(width: 8),
                  _buildPromptChip(LucideIcons.userCheck, 'Mock Interview Tips'),
                  const SizedBox(width: 8),
                  _buildPromptChip(LucideIcons.building, 'Top Companies'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // User Input Box Area
            Container(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Icon(LucideIcons.bot, size: 16, color: AppTheme.accentCoral),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _textCtrl,
                            decoration: InputDecoration(
                              hintText: 'Ask Spark anything...',
                              hintStyle: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                              border: InputBorder.none,
                            ),
                            style: GoogleFonts.inter(fontSize: 11),
                            onSubmitted: (val) => _sendMessage(val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _isLoading ? null : () => _sendMessage(_textCtrl.text),
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppTheme.accentCoral,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.arrowUpRight, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.shieldCheck, size: 11, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        'Spark is your trusted placement companion.',
                        style: GoogleFonts.inter(fontSize: 9.5, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the Claude-style thinking status indicator widget.
  Widget _buildThinkingWidget(ThemeData theme) {
    final currentStatus = _thinkingSteps[_thinkingStepIndex];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentCoral.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentCoral.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RivePlaceholder(width: 22, height: 22, label: 'Spark', icon: LucideIcons.sparkles),
          const SizedBox(width: 10),
          SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentCoral),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              currentStatus,
              key: ValueKey<String>(currentStatus),
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentCoral,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBubble(_Message msg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          decoration: const BoxDecoration(
            color: AppTheme.accentCoral,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            msg.content,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 11, height: 1.4),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(msg.time, style: GoogleFonts.inter(fontSize: 8.5, color: Colors.grey)),
            const SizedBox(width: 4),
            const Icon(Icons.done_all, size: 11, color: AppTheme.accentCoral),
          ],
        ),
      ],
    );
  }

  Widget _buildAiBubble(_Message msg, {bool isFirst = false}) {
    final theme = Theme.of(context);
    final baseStyle = GoogleFonts.inter(
      color: theme.colorScheme.onSurface,
      fontSize: 11,
      height: 1.45,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RivePlaceholder(width: 32, height: 32, label: 'Spark', icon: LucideIcons.bot),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(color: AppTheme.accentCoral.withValues(alpha: isFirst ? 0.25 : 0.08)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFirst) ...[
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(fontSize: 11, color: theme.colorScheme.onSurface),
                          children: [
                            const TextSpan(text: 'Hi! I\'m '),
                            TextSpan(text: 'Spark', style: TextStyle(color: AppTheme.accentCoral, fontWeight: FontWeight.bold)),
                            const TextSpan(text: ' 👋 Your placement companion.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    FormattedMarkdownText(
                      text: msg.content,
                      style: baseStyle,
                      accentColor: AppTheme.accentCoral,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(msg.time, style: GoogleFonts.inter(fontSize: 8.5, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromptChip(IconData icon, String label) {
    return GestureDetector(
      onTap: () => _sendMessage(label, isPredefined: true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppTheme.accentCoral),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }
}

/// A custom high-performance Markdown formatted text renderer.
/// Renders **bold**, *italic*, `code`, bullet points, and numbered lists.
class FormattedMarkdownText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color accentColor;

  const FormattedMarkdownText({
    super.key,
    required this.text,
    required this.style,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final List<Widget> children = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trimRight();
      if (line.isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }

      final isBullet = RegExp(r'^(\s*[-*•])\s+').hasMatch(line);
      final isNumbered = RegExp(r'^(\s*\d+\.)\s+').hasMatch(line);

      String content = line;
      Widget? prefix;

      if (isBullet) {
        content = line.replaceFirst(RegExp(r'^(\s*[-*•])\s+'), '');
        prefix = Container(
          margin: const EdgeInsets.only(top: 6, right: 8),
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
          ),
        );
      } else if (isNumbered) {
        final match = RegExp(r'^(\s*\d+\.)\s+').firstMatch(line);
        final numStr = match?.group(1)?.trim() ?? '1.';
        content = line.replaceFirst(RegExp(r'^(\s*\d+\.)\s+'), '');
        prefix = Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Text(
            numStr,
            style: style.copyWith(
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
        );
      }

      final spans = _parseInlineFormatting(content, style, accentColor);

      final textWidget = RichText(
        text: TextSpan(
          style: style,
          children: spans,
        ),
      );

      if (prefix != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 3.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                prefix,
                Expanded(child: textWidget),
              ],
            ),
          ),
        );
      } else {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 3.0),
            child: textWidget,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  List<TextSpan> _parseInlineFormatting(String input, TextStyle baseStyle, Color accentColor) {
    final List<TextSpan> spans = [];
    final RegExp regExp = RegExp(r'(\*\*.*?\*\*|\*.*?\*|`.*?`)');

    int lastEnd = 0;
    for (final Match match in regExp.allMatches(input)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: input.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      final matchedText = match.group(0)!;
      if (matchedText.startsWith('**') && matchedText.endsWith('**') && matchedText.length >= 4) {
        final inner = matchedText.substring(2, matchedText.length - 2);
        spans.add(TextSpan(
          text: inner,
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: baseStyle.color?.withValues(alpha: 0.95),
          ),
        ));
      } else if (matchedText.startsWith('*') && matchedText.endsWith('*') && matchedText.length >= 2) {
        final inner = matchedText.substring(1, matchedText.length - 1);
        spans.add(TextSpan(
          text: inner,
          style: baseStyle.copyWith(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ));
      } else if (matchedText.startsWith('`') && matchedText.endsWith('`') && matchedText.length >= 2) {
        final inner = matchedText.substring(1, matchedText.length - 1);
        spans.add(TextSpan(
          text: inner,
          style: baseStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: Colors.black.withValues(alpha: 0.05),
            fontWeight: FontWeight.w600,
          ),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < input.length) {
      spans.add(TextSpan(
        text: input.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }
}
