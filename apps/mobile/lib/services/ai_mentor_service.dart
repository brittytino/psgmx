import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/daily_five.dart';
import 'offline_companion.dart';
import 'trusted_api_response.dart';

/// The AI Mentor service — wraps OpenRouter with a fallback model chain.
///
/// Scope:
///   1. Explain a wrong daily-five answer (ephemeral — called in results window)
///   2. Weekly weak-topic note (based on streak/accuracy rates — not raw answers)
///   3. Optional student-initiated resume feedback / mock interview chat
///
/// Fallback chain: if the first model is down or rate-limited, the next takes
/// over automatically. If all models fail, a pre-written tip is returned so
/// the AI layer is never visibly the reason something breaks.
class AiMentorService {
  AiMentorService();

  String? _conversationId;

  void resetConversation() => _conversationId = null;

  // ── Core: OpenRouter call with fallback chain ──────────────────────────────

  /// Calls OpenRouter with the given [systemPrompt] and [userMessage].
  /// Tries each model in [_modelChain] in order.
  /// Returns null if all models fail.
  Future<String?> _callOpenRouter({
    required String intent,
    required String userMessage,
    int maxTokens = 300,
  }) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) return null;
    try {
      final response = await http
          .post(
            Uri.parse('${SupabaseConfig.appApiUrl}/api/ai-mentor'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json'
            },
            body: jsonEncode({
              'intent': intent,
              'message': userMessage,
              'max_tokens': maxTokens
            }),
          )
          .timeout(const Duration(seconds: 22));
      final data = decodeTrustedJson(response,
          fallbackMessage: 'AI Senior is temporarily unavailable.');
      return (data['answer'] as String?)?.trim();
    } catch (error) {
      debugPrint('[AiMentor] Trusted API call failed: $error');
      return null;
    }
  }

  // ── Feature 1: Explain wrong Daily Five answer ────────────────────────────

  /// Explains why [userAnswer] was wrong for [question] and what the correct
  /// answer [correctAnswer] is.
  ///
  /// Called ONLY in the Daily Five results window while the session is still
  /// in memory. Never stores the question or answer in the DB.
  ///
  /// [question.correctOption] must be populated — the caller is expected
  /// to have already revealed it via DailyFiveService.fetchTodaysResults()
  /// (only possible post-submission; see get_daily_five_results RPC).
  Future<String> explainWrongAnswer({
    required DailyFiveQuestion question,
    required int userAnswerIndex,
    required String topic,
  }) async {
    final correctOption = question.correctOption;
    if (correctOption == null) {
      throw StateError(
          'correctOption not revealed yet — call fetchTodaysResults() after submission first');
    }
    final userAnswer = question.options[userAnswerIndex];
    final correctAnswer = question.options[correctOption];

    final userMessage = 'Question: ${question.questionText}\n'
        'Student answered: $userAnswer\n'
        'Correct answer: $correctAnswer\n'
        'Topic: $topic\n'
        'Please explain why the correct answer is right.';

    final aiResponse = await _callOpenRouter(
      intent: 'answer_explanation',
      userMessage: userMessage,
      maxTokens: 200,
    );

    return aiResponse ??
        'AI explanation is temporarily unavailable. Your answer and the verified correct option remain available; please retry shortly.';
  }

  // ── Feature 2: Weekly weak-topic note ────────────────────────────────────

  /// Generates a short weekly note pointing at the student's weakest topic,
  /// based on their stored [accuracyByTopic] map and [currentStreak].
  ///
  /// Does NOT use raw answer history — only aggregate accuracy rates.
  Future<String> getWeeklyWeakTopicNote({
    required Map<String, double> accuracyByTopic,
    required int currentStreak,
    String? name,
  }) async {
    if (accuracyByTopic.isEmpty) {
      return '🌟 Complete your Daily Five today to start building your streak!';
    }

    // Find lowest-accuracy topic
    final weakest =
        accuracyByTopic.entries.reduce((a, b) => a.value < b.value ? a : b);

    final weakTopic = weakest.key;
    final weakPct = (weakest.value * 100).toStringAsFixed(0);

    final greeting = name != null ? 'Hey $name! ' : 'Hey! ';
    final userMessage =
        '${greeting}My weakest topic this week is "$weakTopic" ($weakPct% accuracy). '
        'My current streak is $currentStreak days. Give me a quick tip.';

    final aiResponse = await _callOpenRouter(
      intent: 'weekly_coaching',
      userMessage: userMessage,
      maxTokens: 150,
    );

    return aiResponse ??
        'AI coaching is temporarily unavailable. Your measured weakest topic is "$weakTopic" at $weakPct%; retry for a personalized action.';
  }

  // ── Feature 3: Mock interview / resume feedback chat ─────────────────────

  /// Sends a chat message to the AI mentor for mock interview or resume feedback.
  /// [history] is a list of {role, content} maps representing the conversation so far.
  Future<String> sendMockInterviewMessage({
    required String message,
    required List<Map<String, String>> history,
    bool isResumeFeedback = false,
    OfflineCompanionContext offlineContext = const OfflineCompanionContext(),
  }) async {
    if (isResumeFeedback) {
      final aiResponse = await _callOpenRouter(
        intent: 'resume_feedback',
        userMessage: message,
        maxTokens: 400,
      );
      return aiResponse ??
          OfflineCompanion.answer(message, context: offlineContext);
    }

    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token != null) {
      try {
        final response = await http
            .post(
              Uri.parse('${SupabaseConfig.appApiUrl}/api/ai-senior'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'query': message,
                if (_conversationId != null) 'conversation_id': _conversationId,
              }),
            )
            .timeout(const Duration(seconds: 45));
        final data = decodeTrustedJson(response,
            fallbackMessage: 'AI Senior is temporarily unavailable.');
        final answer = data['answer']?.toString().trim();
        final conversationId = data['conversation_id']?.toString().trim();
        if (conversationId?.isNotEmpty == true) {
          _conversationId = conversationId;
        }
        if (answer?.isNotEmpty == true) return answer!;
      } catch (error) {
        debugPrint('[AiMentor] Personalised AI request failed: $error');
      }
    }

    return OfflineCompanion.answer(message, context: offlineContext);
  }
}
