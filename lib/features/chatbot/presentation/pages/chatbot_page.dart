import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/chatbot/domain/chatbot_service.dart';
import 'package:twezimbeapp/features/chatbot/presentation/pages/chat_history_page.dart';

enum _ChatMenuAction { chatHistory, startNewChat, deletePreviousChats }

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
  bool _isManagingChats = false;
  String? _activeConversationId;

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
    if (_isAwaitingReply || _isManagingChats) {
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
      final conversationId =
          _activeConversationId ??
          await AppDataRepository.getOrCreateActiveChatConversationIdForCurrentUser();

      await AppDataRepository.addChatMessageForCurrentUser(
        isUser: true,
        text: input,
        conversationId: conversationId,
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
        conversationId: conversationId,
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

  Future<void> _startNewChat() async {
    if (_isAwaitingReply || _isManagingChats) {
      return;
    }

    setState(() => _isManagingChats = true);
    try {
      final conversationId =
          await AppDataRepository.startNewChatForCurrentUser();
      if (!mounted) {
        return;
      }
      setState(() {
        _activeConversationId = conversationId;
      });
      _scrollToBottom();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Started a new chat.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start a new chat. $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isManagingChats = false);
      }
    }
  }

  Future<void> _deletePreviousChats() async {
    final activeConversationId = _activeConversationId?.trim() ?? '';
    if (activeConversationId.isEmpty || _isManagingChats) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Previous Chats'),
          content: const Text(
            'Delete all previous chats and keep only the current chat?',
          ),
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

    setState(() => _isManagingChats = true);
    try {
      final deletedCount =
          await AppDataRepository.deletePreviousChatConversationsForCurrentUser(
            keepConversationId: activeConversationId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deletedCount > 0
                ? 'Deleted previous chats.'
                : 'No previous chats found.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete previous chats. $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isManagingChats = false);
      }
    }
  }

  Future<void> _openChatHistory() async {
    if (_isAwaitingReply || _isManagingChats) {
      return;
    }

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const ChatHistoryPage()),
    );
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
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primaryBlue.withValues(
                            alpha: 0.12,
                          ),
                          child: const Icon(
                            Icons.smart_toy_outlined,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chat Assistant',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: const [
                                Icon(
                                  Icons.circle,
                                  size: 9,
                                  color: Color(0xFF22C55E),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Online',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF22C55E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<_ChatMenuAction>(
                    enabled: !_isAwaitingReply && !_isManagingChats,
                    onSelected: (action) async {
                      switch (action) {
                        case _ChatMenuAction.chatHistory:
                          await _openChatHistory();
                          break;
                        case _ChatMenuAction.startNewChat:
                          await _startNewChat();
                          break;
                        case _ChatMenuAction.deletePreviousChats:
                          await _deletePreviousChats();
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<_ChatMenuAction>(
                        value: _ChatMenuAction.chatHistory,
                        child: Text('Chat history'),
                      ),
                      PopupMenuItem<_ChatMenuAction>(
                        value: _ChatMenuAction.startNewChat,
                        child: Text('Start new chat'),
                      ),
                      PopupMenuItem<_ChatMenuAction>(
                        value: _ChatMenuAction.deletePreviousChats,
                        child: Text('Delete previous chats'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<String?>(
                stream:
                    AppDataRepository.watchActiveChatConversationIdForCurrentUser(),
                builder: (context, activeConversationSnapshot) {
                  final activeConversationId = activeConversationSnapshot.data;
                  _activeConversationId = activeConversationId;

                  if (activeConversationId == null ||
                      activeConversationId.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return StreamBuilder<List<AppChatMessageData>>(
                    stream: AppDataRepository.watchChatMessagesForCurrentUser(
                      conversationId: activeConversationId,
                    ),
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
                                                title: const Text(
                                                  'Edit message',
                                                ),
                                                onTap: () async {
                                                  Navigator.pop(context);
                                                  await _editMessage(message);
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(
                                                  Icons.delete_outline,
                                                ),
                                                title: const Text(
                                                  'Delete message',
                                                ),
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
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                mainAxisAlignment: message.isUser
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!message.isUser) ...[
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.primaryBlue
                                          .withValues(alpha: 0.12),
                                      child: const Icon(
                                        Icons.smart_toy_outlined,
                                        color: AppColors.primaryBlue,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.74,
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
                                  if (message.isUser) ...[
                                    const SizedBox(width: 8),
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.primaryBlue,
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
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
                      enabled: !_isAwaitingReply && !_isManagingChats,
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
                      onPressed: _isAwaitingReply || _isManagingChats
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
