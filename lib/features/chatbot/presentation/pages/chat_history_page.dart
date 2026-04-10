import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';

class ChatHistoryPage extends StatelessWidget {
  const ChatHistoryPage({super.key});

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) {
      return 'No timestamp';
    }

    final y = timestamp.year.toString().padLeft(4, '0');
    final m = timestamp.month.toString().padLeft(2, '0');
    final d = timestamp.day.toString().padLeft(2, '0');
    final hh = timestamp.hour.toString().padLeft(2, '0');
    final mm = timestamp.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat History'), centerTitle: true),
      body: StreamBuilder<String?>(
        stream: AppDataRepository.watchActiveChatConversationIdForCurrentUser(),
        builder: (context, activeSnapshot) {
          final activeConversationId = activeSnapshot.data;

          return StreamBuilder<List<AppChatConversationData>>(
            stream: AppDataRepository.watchChatConversationsForCurrentUser(),
            builder: (context, historySnapshot) {
              final conversations =
                  historySnapshot.data ?? const <AppChatConversationData>[];

              if (conversations.isEmpty) {
                return const Center(child: Text('No chat history yet.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: conversations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  final isActive = activeConversationId == conversation.id;
                  final subtitle = conversation.lastMessage.isEmpty
                      ? 'No messages in this session yet.'
                      : conversation.lastMessage;

                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        await AppDataRepository.setActiveChatConversationIdForCurrentUser(
                          conversation.id,
                        );
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.pop(context, true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? AppColors.primaryBlue
                                : Colors.grey.shade200,
                            width: isActive ? 1.6 : 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline,
                                color: AppColors.primaryBlue,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    conversation.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTimestamp(
                                      conversation.lastMessageAt,
                                    ),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${conversation.unreadCount}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'unread',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                                if (isActive) ...[
                                  const SizedBox(height: 6),
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primaryBlue,
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
