import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/chatbot/domain/chatbot_service.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final ChatbotService _chatbotService = ChatbotService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAwaitingReply = false;
  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      isUser: false,
      text:
          'Welcome to Twezimbe assistant. You can ask me questions about the app, how to use it, or any other inquiries you may have. I\'m here to help you get the most out of your experience with Twezimbe. Just type your question below and I\'ll do my best to assist you!',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    if (_isAwaitingReply) {
      return;
    }

    final input = _controller.text.trim();
    if (input.isEmpty) {
      return;
    }

    final placeholder = const _ChatMessage(isUser: false, text: '...');

    setState(() {
      _isAwaitingReply = true;
      _messages.add(_ChatMessage(isUser: true, text: input));
      _messages.add(placeholder);
      _controller.clear();
    });
    _scrollToBottom();

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) {
      return;
    }

    final reply = _chatbotService.getResponse(input);
    setState(() {
      final int placeholderIndex = _messages.lastIndexOf(placeholder);
      if (placeholderIndex >= 0) {
        _messages[placeholderIndex] = _ChatMessage(isUser: false, text: reply);
      } else {
        _messages.add(_ChatMessage(isUser: false, text: reply));
      }
      _isAwaitingReply = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Chat Assistant',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Align(
                    alignment: message.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.84,
                      ),
                      decoration: BoxDecoration(
                        color: message.isUser
                            ? AppColors.primaryBlue
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: message.isUser
                              ? AppColors.primaryBlue
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser
                              ? Colors.white
                              : AppColors.textMain,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      enabled: !_isAwaitingReply,
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        _sendMessage();
                      },
                      decoration: const InputDecoration(
                        hintText: 'Type your question',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: ElevatedButton(
                      onPressed: _isAwaitingReply
                          ? null
                          : () {
                              _sendMessage();
                            },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Icon(Icons.send, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.isUser, required this.text});

  final bool isUser;
  final String text;
}
