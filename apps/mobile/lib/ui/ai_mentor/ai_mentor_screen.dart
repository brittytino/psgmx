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
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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

  Future<void> _sendMessage(String text) async {
    final messageText = text.trim();
    if (messageText.isEmpty) return;

    _textCtrl.clear();
    setState(() {
      _messages.add(_Message(messageText, true, _getCurrentTime()));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final history = _messages.map((m) => {
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.content,
      }).toList();

      final response = await _service.sendMockInterviewMessage(
        message: messageText,
        history: history,
        isResumeFeedback: false,
      );

      if (mounted) {
        setState(() {
          _messages.add(_Message(response, false, _getCurrentTime()));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
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
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'AI Mentor',
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.sparkles, color: AppTheme.illusGold, size: 12),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your personal guide to grow smarter.',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.history, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Chat History',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Chat Area
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: msg.isUser 
                        ? _buildUserBubble(msg) 
                        : _buildAiBubble(msg, isFirst: index == 0),
                  );
                },
              ),
            ),
            
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const SizedBox(width: 60),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12, height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentCoral),
                          ),
                          const SizedBox(width: 12),
                          Text('Spark is typing...', style: GoogleFonts.inter(fontSize: 9, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
            // Suggested Prompts
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  _buildPromptChip(LucideIcons.code, 'DSA Study Plan'),
                  const SizedBox(width: 12),
                  _buildPromptChip(LucideIcons.target, 'Aptitude Prep Tips'),
                  const SizedBox(width: 12),
                  _buildPromptChip(LucideIcons.user, 'Mock Interview Tips'),
                  const SizedBox(width: 12),
                  _buildPromptChip(LucideIcons.building, 'Top Companies'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Input Area
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Icon(LucideIcons.paperclip, size: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _textCtrl,
                            decoration: InputDecoration(
                              hintText: 'Ask Spark anything...',
                              hintStyle: GoogleFonts.inter(fontSize: 9, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                              border: InputBorder.none,
                            ),
                            style: GoogleFonts.inter(fontSize: 9),
                            onSubmitted: _sendMessage,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _isLoading ? null : () => _sendMessage(_textCtrl.text),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.accentCoral,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.arrowRight, color: Colors.white, size: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.shieldCheck, size: 10, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        'Spark can make mistakes. Please verify important info.',
                        style: GoogleFonts.inter(fontSize: 9, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
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

  Widget _buildUserBubble(_Message msg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: const BoxDecoration(
            color: AppTheme.accentCoral,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            msg.content,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 9, height: 1.5),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(msg.time, style: GoogleFonts.inter(fontSize: 8, color: Colors.grey)),
            const SizedBox(width: 4),
            const Icon(Icons.done_all, size: 10, color: AppTheme.accentCoral),
          ],
        ),
      ],
    );
  }

  Widget _buildAiBubble(_Message msg, {bool isFirst = false}) {
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  border: Border.all(color: AppTheme.accentCoral.withValues(alpha: isFirst ? 0.2 : 0.0)),
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
                          style: GoogleFonts.inter(fontSize: 9, color: Theme.of(context).colorScheme.onSurface),
                          children: [
                            const TextSpan(text: 'Hi! I\'m '),
                            TextSpan(text: 'Spark', style: TextStyle(color: AppTheme.accentCoral, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      msg.content,
                      style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface, fontSize: 9, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(msg.time, style: GoogleFonts.inter(fontSize: 8, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromptChip(IconData icon, String label) {
    return GestureDetector(
      onTap: () => _sendMessage(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppTheme.accentCoral),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }
}
