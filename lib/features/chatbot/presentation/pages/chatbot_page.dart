import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
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

    setState(() {
      _isAwaitingReply = true;
      _controller.clear();
    });

    try {
      await AppDataRepository.addChatMessageForCurrentUser(
        isUser: true,
        text: input,
      );
      _scrollToBottom();

      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) {
        return;
      }

      final reply = _chatbotService.getResponse(input);
      await AppDataRepository.addChatMessageForCurrentUser(
        isUser: false,
        text: reply,
      );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat unavailable right now. ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAwaitingReply = false;
        });
      }
    }
  }

  Future<void> _editMessage(AppChatMessageData message) async {
    final TextEditingController editController = TextEditingController(
      text: message.text,
    );

    final String? updatedText = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Message'),
          content: TextField(
            controller: editController,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Update message'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, editController.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    editController.dispose();
    if (updatedText == null) {
      return;
    }

    final String cleaned = updatedText.trim();
    if (cleaned.isEmpty) {
      return;
    }

    await AppDataRepository.updateChatMessageForCurrentUser(
      messageId: message.id,
      text: cleaned,
    );
  }

  Future<void> _deleteMessage(AppChatMessageData message) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Message'),
          content: const Text('This message will be removed permanently.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await AppDataRepository.deleteChatMessageForCurrentUser(message.id);
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
              child: StreamBuilder<List<AppChatMessageData>>(
                stream: AppDataRepository.watchChatMessagesForCurrentUser(),
                builder: (context, snapshot) {
                  final messages =
                      snapshot.data ?? const <AppChatMessageData>[];

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return GestureDetector(
                        onLongPress: message.isUser
                            ? () async {
                                await showModalBottomSheet<void>(
                                  context: context,
                                  builder: (context) {
                                    return SafeArea(
                                      child: Wrap(
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.edit),
                                            title: const Text('Edit message'),
                                            onTap: () async {
                                              Navigator.pop(context);
                                              await _editMessage(message);
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            title: const Text('Delete message'),
                                            onTap: () async {
                                              Navigator.pop(context);
                                              await _deleteMessage(message);
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }
                            : null,
                        child: Align(
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
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.84,
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
                        ),
                      );
                    },
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
