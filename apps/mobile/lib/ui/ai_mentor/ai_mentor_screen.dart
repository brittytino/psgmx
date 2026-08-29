import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    "Hi there! I'm Spark, your AI Senior. How can I guide your preparation today?",
    "Hello! Ready to sharpen your skills or work on your preparation? I'm right here with you!",
    "Hey! Great to see you. What topic are we tackling today—DSA, Aptitude, Mock Interviews, or Resume tips?",
    "Good day! Ask me about preparation, interview patterns, projects, or technical skills—I'm here to help.",
    "Hi! I'm excited to assist you on your tech journey. What's on your mind today?",
    "Hello! Step by step, problem by problem—we're making progress. How can I help you today?",
  ];

  // Quick prompts are discovery shortcuts; answers always come from the live,
  // authenticated and Knowledge-Brain-grounded AI service.
  static const Set<String> _quickPromptKeys = {
    'dsa_study_plan',
    'aptitude_prep_tips',
    'mock_interview_tips',
    'interview_patterns',
  };

  @override
  void initState() {
    super.initState();
    _messages.add(_Message(
      "Your AI Senior. Ask about skills, preparation, projects, or your journey — I'm here!",
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
    final clean =
        message.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '');
    const greetings = [
      'hi',
      'hello',
      'hey',
      'heya',
      'howdy',
      'good morning',
      'good afternoon',
      'good evening',
      'namaste',
      'sup',
      'hi spark',
      'hello spark',
      'hey spark',
      'who are you',
      'what can you do',
      'help',
      'thanks',
      'thank you'
    ];
    if (greetings.contains(clean)) {
      return true;
    }
    if (clean.length <= 4 &&
        (clean.startsWith('hi') || clean.startsWith('hey'))) {
      return true;
    }
    return false;
  }

  /// Quick prompts use the same grounded service as typed questions. The
  /// prompt catalogue is only a discoverability aid, never a canned answer.
  Future<String?> _getPredefinedNonRepeatingReply(String prompt) async {
    return _service.sendMockInterviewMessage(
      message: prompt,
      history: _messages
          .map((message) => {
                'role': message.isUser ? 'user' : 'assistant',
                'content': message.content,
              })
          .toList(),
    );
  }

  Future<void> _sendMessage(String text, {bool isPredefined = false}) async {
    final messageText = text.trim();
    if (messageText.isEmpty) return;

    _textCtrl.clear();

    // Check if simple greeting for instant response
    if (_isSimpleGreeting(messageText)) {
      final random = Random();
      final instantReply =
          _simpleGreetingReplies[random.nextInt(_simpleGreetingReplies.length)];
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

      final normalized =
          messageText.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      final isKnownPredefined =
          isPredefined || _quickPromptKeys.contains(normalized);

      if (isKnownPredefined) {
        // Quick actions are live, authenticated AI requests too.
        reply = await _getPredefinedNonRepeatingReply(messageText);
      } else {
        final history = _messages
            .map((m) => {
                  'role': m.isUser ? 'user' : 'assistant',
                  'content': m.content,
                })
            .toList();

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
            reply ??
                'I am here with you. Let\'s try asking that again in a slightly different way!',
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
          _messages.add(_Message('Error connecting to AI. Please try again.',
              false, _getCurrentTime()));
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.illusGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.sparkles,
                                      color: AppTheme.illusGold, size: 10),
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
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.6),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.rotateCcw,
                                size: 12,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text(
                              'Reset',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 16.0),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildThinkingWidget(theme),
                ),
              ),

            // Predefined Quick Action Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Row(
                children: [
                  _buildPromptChip(LucideIcons.code, 'DSA Study Plan'),
                  const SizedBox(width: 8),
                  _buildPromptChip(LucideIcons.target, 'Aptitude Prep Tips'),
                  const SizedBox(width: 8),
                  _buildPromptChip(
                      LucideIcons.userCheck, 'Mock Interview Tips'),
                  const SizedBox(width: 8),
                  _buildPromptChip(
                      LucideIcons.messageSquareText, 'Interview Patterns'),
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
                      border: Border.all(
                          color: Theme.of(context)
                              .dividerColor
                              .withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Icon(LucideIcons.bot,
                            size: 16, color: AppTheme.accentCoral),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _textCtrl,
                            decoration: InputDecoration(
                              hintText: 'Ask Spark anything...',
                              hintStyle: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withValues(alpha: 0.5)),
                              border: InputBorder.none,
                            ),
                            style: GoogleFonts.inter(fontSize: 11),
                            onSubmitted: (val) => _sendMessage(val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () => _sendMessage(_textCtrl.text),
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppTheme.accentCoral,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.arrowUpRight,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.shieldCheck,
                          size: 11,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        'Spark is your trusted placement companion.',
                        style: GoogleFonts.inter(
                            fontSize: 9.5,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.6)),
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
          const RivePlaceholder(
              width: 22,
              height: 22,
              label: 'Spark',
              icon: LucideIcons.sparkles),
          const SizedBox(width: 10),
          SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.accentCoral),
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
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78),
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
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 11, height: 1.4),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(msg.time,
                style: GoogleFonts.inter(fontSize: 8.5, color: Colors.grey)),
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
        const RivePlaceholder(
            width: 32, height: 32, label: 'Spark', icon: LucideIcons.bot),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(
                      color: AppTheme.accentCoral
                          .withValues(alpha: isFirst ? 0.25 : 0.08)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isFirst) ...[
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                              fontSize: 11, color: theme.colorScheme.onSurface),
                          children: [
                            const TextSpan(text: 'Hi! I\'m '),
                            TextSpan(
                                text: 'Spark',
                                style: TextStyle(
                                    color: AppTheme.accentCoral,
                                    fontWeight: FontWeight.bold)),
                            const TextSpan(
                                text: ' 👋 Your placement companion.'),
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
              Text(msg.time,
                  style: GoogleFonts.inter(fontSize: 8.5, color: Colors.grey)),
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
          border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
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
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface)),
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

  List<TextSpan> _parseInlineFormatting(
      String input, TextStyle baseStyle, Color accentColor) {
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
      if (matchedText.startsWith('**') &&
          matchedText.endsWith('**') &&
          matchedText.length >= 4) {
        final inner = matchedText.substring(2, matchedText.length - 2);
        spans.add(TextSpan(
          text: inner,
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: baseStyle.color?.withValues(alpha: 0.95),
          ),
        ));
      } else if (matchedText.startsWith('*') &&
          matchedText.endsWith('*') &&
          matchedText.length >= 2) {
        final inner = matchedText.substring(1, matchedText.length - 1);
        spans.add(TextSpan(
          text: inner,
          style: baseStyle.copyWith(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
          ),
        ));
      } else if (matchedText.startsWith('`') &&
          matchedText.endsWith('`') &&
          matchedText.length >= 2) {
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
