import 'package:flutter/material.dart';
import '../../services/ai_mentor_service.dart';
import '../../core/theme/app_dimens.dart';

class AiMentorScreen extends StatefulWidget {
  const AiMentorScreen({super.key});

  @override
  State<AiMentorScreen> createState() => _AiMentorScreenState();
}

class _Message {
  final String content;
  final bool isUser;

  _Message(this.content, this.isUser);
}

class _AiMentorScreenState extends State<AiMentorScreen> {
  final _service = AiMentorService();
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  
  final List<_Message> _messages = [];
  bool _isLoading = false;
  bool _isResumeFeedback = false;

  @override
  void initState() {
    super.initState();
    _messages.add(_Message(
      "Hi! I'm your AI Mentor. We can practice a technical mock interview or review your resume. How can I help you today?",
      false
    ));
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    _textCtrl.clear();
    setState(() {
      _messages.add(_Message(text, true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final history = _messages.map((m) => {
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.content,
      }).toList();

      final response = await _service.sendMockInterviewMessage(
        message: text,
        history: history,
        isResumeFeedback: _isResumeFeedback,
      );

      if (mounted) {
        setState(() {
          _messages.add(_Message(response, false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_Message('Error connecting to AI. Please try again.', false));
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
      appBar: AppBar(
        title: const Text('AI Mentor'),
        actions: [
          PopupMenuButton<bool>(
            initialValue: _isResumeFeedback,
            onSelected: (val) {
              setState(() {
                _isResumeFeedback = val;
                _messages.clear();
                _messages.add(_Message(
                  val ? "Ready for a resume review. What would you like me to look at?" 
                      : "Mock interview mode active. Whenever you're ready, say hello!",
                  false
                ));
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: false, child: Text('Mock Interview')),
              PopupMenuItem(value: true, child: Text('Resume Review')),
            ],
            icon: const Icon(Icons.tune),
            tooltip: 'Change Mode',
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: theme.colorScheme.surfaceContainerHighest,
            width: double.infinity,
            child: Text(
              _isResumeFeedback ? 'Mode: Resume Review' : 'Mode: Mock Interview',
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg, theme);
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  const Text('Mentor is typing...'),
                ],
              ),
            ),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_Message msg, ThemeData theme) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: msg.isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: msg.isUser ? const Radius.circular(0) : null,
            bottomLeft: !msg.isUser ? const Radius.circular(0) : null,
          ),
        ),
        child: Text(
          msg.content,
          style: TextStyle(color: msg.isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface),
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textCtrl,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: IconButton(
                icon: Icon(Icons.send, color: theme.colorScheme.onPrimary, size: 20),
                onPressed: _isLoading ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
