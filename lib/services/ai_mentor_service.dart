import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/supabase_config.dart';
import '../models/daily_five.dart';

/// The AI Mentor service — wraps OpenRouter with a fallback model chain.
///
/// Scope (per Agent.md Section 8):
///   1. Explain a wrong daily-five answer (ephemeral — called in results window)
///   2. Weekly weak-topic note (based on streak/accuracy rates — not raw answers)
///   3. Optional student-initiated resume feedback / mock interview chat
///
/// Fallback chain: if the first model is down or rate-limited, the next takes
/// over automatically. If all models fail, a pre-written tip is returned so
/// the AI layer is never visibly the reason something breaks.
class AiMentorService {
  static const String _openRouterBaseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  /// Ordered list of free OpenRouter models to try.
  static const List<String> _modelChain = [
    'meta-llama/llama-3.3-8b-instruct:free',
    'google/gemma-3-12b-it:free',
    'mistralai/mistral-7b-instruct:free',
  ];

  /// Pre-written fallback tips for wrong Daily Five answers, by topic.
  static const Map<String, String> _fallbackTips = {
    'default': '💡 Tip: Review the concept once more and try to explain it in '
        'your own words — active recall is the most effective study technique.',
    'aptitude': '💡 Tip: For quantitative problems, always note the units and '
        'check if a simplified formula applies.',
    'dsa': '💡 Tip: Trace through the algorithm with a small example input '
        'to see where your mental model differs from the correct answer.',
    'os': '💡 Tip: Operating systems concepts often have analogies in everyday '
        'life — try mapping the concept to something familiar.',
    'dbms': '💡 Tip: Draw the schema or query plan on paper; visualization '
        'makes it much easier to spot the correct relationship.',
    'networking': '💡 Tip: Remember the OSI layers from bottom to top: '
        'Physical → Data Link → Network → Transport → Session → Presentation → Application.',
  };

  AiMentorService();

  // ── Core: OpenRouter call with fallback chain ──────────────────────────────

  /// Calls OpenRouter with the given [systemPrompt] and [userMessage].
  /// Tries each model in [_modelChain] in order.
  /// Returns null if all models fail.
  Future<String?> _callOpenRouter({
    required String systemPrompt,
    required String userMessage,
    int maxTokens = 300,
  }) async {
    final apiKey = SupabaseConfig.openRouterApiKey;
    if (apiKey.isEmpty) {
      debugPrint('[AiMentor] No OpenRouter API key — skipping AI call');
      return null;
    }

    for (final model in _modelChain) {
      try {
        final response = await http
            .post(
              Uri.parse(_openRouterBaseUrl),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
                'HTTP-Referer': 'https://psgmx.app',
                'X-Title': 'PSGMX AI Mentor',
              },
              body: jsonEncode({
                'model': model,
                'max_tokens': maxTokens,
                'messages': [
                  {'role': 'system', 'content': systemPrompt},
                  {'role': 'user', 'content': userMessage},
                ],
              }),
            )
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final content =
              data['choices']?[0]?['message']?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            debugPrint('[AiMentor] ✅ Response from $model');
            return content.trim();
          }
        } else if (response.statusCode == 429 || response.statusCode == 503) {
          debugPrint(
              '[AiMentor] Model $model returned ${response.statusCode}, trying next');
          continue;
        }
      } catch (e) {
        debugPrint('[AiMentor] Model $model error: $e — trying next');
        continue;
      }
    }
    debugPrint('[AiMentor] All models failed — using fallback');
    return null;
  }

  // ── Feature 1: Explain wrong Daily Five answer ────────────────────────────

  /// Explains why [userAnswer] was wrong for [question] and what the correct
  /// answer [correctAnswer] is.
  ///
  /// Called ONLY in the Daily Five results window while the session is still
  /// in memory. Never stores the question or answer in the DB.
  Future<String> explainWrongAnswer({
    required DailyFiveQuestion question,
    required int userAnswerIndex,
    required String topic,
  }) async {
    final userAnswer = question.options[userAnswerIndex];
    final correctAnswer = question.options[question.correctOption];

    const systemPrompt =
        'You are a concise placement-prep tutor for MCA students. '
        'When shown a question, the student\'s wrong answer, and the correct answer, '
        'explain WHY the correct answer is right in 2–4 short sentences. '
        'Be specific, use examples where helpful, and keep it encouraging.';

    final userMessage =
        'Question: ${question.questionText}\n'
        'Student answered: $userAnswer\n'
        'Correct answer: $correctAnswer\n'
        'Topic: $topic\n'
        'Please explain why the correct answer is right.';

    final aiResponse = await _callOpenRouter(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      maxTokens: 200,
    );

    return aiResponse ?? (_fallbackTips[topic.toLowerCase()] ?? _fallbackTips['default']!);
  }

  // ── Feature 2: Weekly weak-topic note ────────────────────────────────────

  /// Generates a short weekly note pointing at the student's weakest topic,
  /// based on their stored [accuracyByTopic] map and [currentStreak].
  ///
  /// Does NOT use raw answer history — only aggregate accuracy rates, which
  /// are retained per Agent.md Section 6.
  Future<String> getWeeklyWeakTopicNote({
    required Map<String, double> accuracyByTopic,
    required int currentStreak,
    String? name,
  }) async {
    if (accuracyByTopic.isEmpty) {
      return '🌟 Complete your Daily Five today to start building your streak!';
    }

    // Find lowest-accuracy topic
    final weakest = accuracyByTopic.entries
        .reduce((a, b) => a.value < b.value ? a : b);

    final weakTopic = weakest.key;
    final weakPct = (weakest.value * 100).toStringAsFixed(0);

    const systemPrompt =
        'You are an encouraging placement-prep coach. '
        'Give a student a short motivational note (2–3 sentences) about their '
        'weakest topic, with one specific actionable tip to improve. Be warm and direct.';

    final greeting = name != null ? 'Hey $name! ' : 'Hey! ';
    final userMessage =
        '${greeting}My weakest topic this week is "$weakTopic" (${weakPct}% accuracy). '
        'My current streak is $currentStreak days. Give me a quick tip.';

    final aiResponse = await _callOpenRouter(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      maxTokens: 150,
    );

    return aiResponse ??
        '📚 Focus on "$weakTopic" this week — even 20 minutes of targeted practice '
            'can shift your accuracy significantly. Keep your $currentStreak-day streak going!';
  }

  // ── Feature 3: Mock interview / resume feedback chat ─────────────────────

  /// Sends a chat message to the AI mentor for mock interview or resume feedback.
  /// [history] is a list of {role, content} maps representing the conversation so far.
  Future<String> sendMockInterviewMessage({
    required String message,
    required List<Map<String, String>> history,
    bool isResumeFeedback = false,
  }) async {
    final systemPrompt = isResumeFeedback
        ? 'You are an experienced technical recruiter reviewing an MCA student\'s resume. '
            'Give specific, constructive feedback on content, formatting, and impact. '
            'Focus on placement readiness for software engineering roles.'
        : 'You are a senior software engineer conducting a friendly mock technical interview '
            'for an MCA student. Ask one question at a time, give feedback, then move on. '
            'Cover DSA, OS, DBMS, CN, and aptitude. Keep a conversational tone.';

    final aiResponse = await _callOpenRouter(
      systemPrompt: systemPrompt,
      userMessage: message,
      maxTokens: 400,
    );

    return aiResponse ??
        'I\'m having trouble connecting right now. Please try again in a moment! '
            'In the meantime, try explaining your answer out loud — it\'s great practice.';
  }
}
