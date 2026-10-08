import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/daily_five.dart';
import 'offline_companion.dart';
import 'trusted_api_response.dart';

/// The AI Mentor service — wraps OpenRouter directly and via backend broker
/// with a robust multi-model fallback chain.
///
/// Models tried in order:
/// 1. deepseek/deepseek-chat
/// 2. meta-llama/llama-3.3-70b-instruct:free
/// 3. google/gemini-2.0-flash-exp:free
/// 4. mistralai/mistral-small-24b-instruct-2501:free
/// 5. qwen/qwen-2.5-72b-instruct:free
///
/// When offline or if network fails, falls back seamlessly to the
/// comprehensive, grounded OfflineCompanion so the AI Senior always
/// responds live and intelligently.
class AiMentorService {
  AiMentorService();

  String? _conversationId;

  static const List<String> _modelChain = [
    'nvidia/nemotron-3-ultra-550b-a55b:free',
    'poolside/laguna-s-2.1:free',
    'nvidia/nemotron-3.5-lightning:free',
    'nvidia/nemotron-3-super-120b-a12b:free',
    'dots-studio/dots-3-note-preview:free',
    'thinkingmachines/inkling:free',
    'poolside/laguna-xs-2.1:free',
    'google/gemma-4-26b-a4b-it:free',
    'google/gemma-4-31b-it:free',
    'fish-audio/s2.1-pro-free:free',
  ];

  void resetConversation() => _conversationId = null;

  // ── Core: Direct OpenRouter Call ──────────────────────────────────────────

  Future<String?> _callOpenRouterDirect({
    required String systemPrompt,
    required String userMessage,
    List<Map<String, String>> history = const [],
    int maxTokens = 450,
  }) async {
    final apiKey = SupabaseConfig.openRouterApiKey.trim();
    if (apiKey.isEmpty) return null;

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ...history,
      {'role': 'user', 'content': userMessage},
    ];

    for (final model in _modelChain) {
      try {
        debugPrint('[AiMentor] Calling OpenRouter model: $model');
        final response = await http
            .post(
              Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
                'HTTP-Referer': 'https://app.psgmx.tech',
                'X-Title': 'PSGMX AI Senior',
              },
              body: jsonEncode({
                'model': model,
                'messages': messages,
                'max_tokens': maxTokens,
                'temperature': 0.7,
              }),
            )
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
          final choices = data['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final content = choices[0]['message']?['content']?.toString().trim();
            if (content != null && content.isNotEmpty) {
              debugPrint('[AiMentor] ✅ OpenRouter response received from $model');
              return content;
            }
          }
        } else {
          debugPrint(
              '[AiMentor] OpenRouter model $model returned ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        debugPrint('[AiMentor] Error with model $model: $e');
      }
    }

    return null;
  }

  // ── Core: Backend API Proxy Call ──────────────────────────────────────────

  Future<String?> _callOpenRouterProxy({
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
          .timeout(const Duration(seconds: 60));
      final data = decodeTrustedJson(response,
          fallbackMessage: 'AI Senior is temporarily unavailable.');
      return (data['answer'] as String?)?.trim();
    } catch (error) {
      debugPrint('[AiMentor] Trusted backend call failed: $error');
      return null;
    }
  }

  // ── Feature 1: Explain wrong Daily Five answer ────────────────────────────

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
        'Explain concisely why the correct option is right and what common misconception led to the student\'s choice.';

    final directResponse = await _callOpenRouterDirect(
      systemPrompt:
          'You are Spark, the PSG Tech MCA Placement AI Senior. Provide clear, encouraging, conceptual explanations for quiz questions. Focus on the core reason, edge cases, and why the correct answer holds.',
      userMessage: userMessage,
      maxTokens: 250,
    );
    if (directResponse != null && directResponse.isNotEmpty) {
      return directResponse;
    }

    final proxyResponse = await _callOpenRouterProxy(
      intent: 'answer_explanation',
      userMessage: userMessage,
      maxTokens: 200,
    );
    if (proxyResponse != null && proxyResponse.isNotEmpty) {
      return proxyResponse;
    }

    return '''**Correct Answer:** $correctAnswer

**Why this is correct:** In $topic, $correctAnswer accurately satisfies the core constraints and logic of the question.

**Key Takeaway:** Review this concept to ensure you recall the fundamental formula or rule when it reappears in your next placement assessment!''';
  }

  // ── Feature 2: Weekly weak-topic note ────────────────────────────────────

  Future<String> getWeeklyWeakTopicNote({
    required Map<String, double> accuracyByTopic,
    required int currentStreak,
    String? name,
  }) async {
    if (accuracyByTopic.isEmpty) {
      return '🌟 Complete your Daily Five today to start building your streak!';
    }

    final weakest =
        accuracyByTopic.entries.reduce((a, b) => a.value < b.value ? a : b);

    final weakTopic = weakest.key;
    final weakPct = (weakest.value * 100).toStringAsFixed(0);

    final greeting = name != null ? 'Hey $name! ' : 'Hey! ';
    final userMessage =
        '${greeting}My weakest topic this week is "$weakTopic" ($weakPct% accuracy). '
        'My current streak is $currentStreak days. Give me a quick, actionable placement coaching tip.';

    final directResponse = await _callOpenRouterDirect(
      systemPrompt:
          'You are Spark, the PSG Tech MCA AI Senior mentor. Give a motivating, 2-paragraph coaching tip for a student\'s weakest topic with specific practice steps.',
      userMessage: userMessage,
      maxTokens: 200,
    );
    if (directResponse != null && directResponse.isNotEmpty) {
      return directResponse;
    }

    final proxyResponse = await _callOpenRouterProxy(
      intent: 'weekly_coaching',
      userMessage: userMessage,
      maxTokens: 150,
    );
    if (proxyResponse != null && proxyResponse.isNotEmpty) {
      return proxyResponse;
    }

    return '''${greeting}Your current focus area is **$weakTopic** (measured at $weakPct% accuracy).

💡 **Senior Strategy:**
Dedicate your next 20-minute practice block exclusively to $weakTopic fundamentals. Work through 3 solved examples before attempting a timed drill. With your current $currentStreak-day streak, consistent targeted practice will turn this into one of your strongest areas!''';
  }

  // ── Feature 3: Mock interview / resume feedback / chat ────────────────────

  Future<String> sendMockInterviewMessage({
    required String message,
    required List<Map<String, String>> history,
    bool isResumeFeedback = false,
    OfflineCompanionContext offlineContext = const OfflineCompanionContext(),
  }) async {
    const systemPrompt =
        'You are Spark, the PSG Tech MCA Placement AI Senior mentor. You are warm, knowledgeable, practical, and inspiring. Guide MCA students through technical interview preparation, DSA patterns, Aptitude, Core CS (DBMS, OS, Networks), system design, resume enhancement, and placement strategies. Provide clear, structured, senior-level guidance with actionable tips, examples, and encouragement. Keep responses concise, well-formatted with markdown, and easy to read on mobile.';

    // 1. Direct OpenRouter call
    try {
      final directResponse = await _callOpenRouterDirect(
        systemPrompt: systemPrompt,
        userMessage: message,
        history: history,
        maxTokens: 500,
      );
      if (directResponse != null && directResponse.isNotEmpty) {
        return directResponse;
      }
    } catch (e) {
      debugPrint('[AiMentor] Direct OpenRouter attempt error: $e');
    }

    // 2. Web backend proxy call
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
            .timeout(const Duration(seconds: 60));
        final data = decodeTrustedJson(response,
            fallbackMessage: 'AI Senior is temporarily unavailable.');
        final answer = data['answer']?.toString().trim();
        final conversationId = data['conversation_id']?.toString().trim();
        if (conversationId?.isNotEmpty == true) {
          _conversationId = conversationId;
        }
        if (answer?.isNotEmpty == true) return answer!;
      } catch (error) {
        debugPrint('[AiMentor] Backend proxy attempt error: $error');
      }
    }

    // 3. Expert grounded guidance (always live and structured)
    return OfflineCompanion.answer(message, context: offlineContext);
  }
}
