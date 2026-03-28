import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppNotificationData>>(
      stream: AppDataRepository.watchNotificationsForCurrentUser(limit: 200),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? const <AppNotificationData>[];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: () {
                  AppDataRepository.markAllNotificationsAsReadForCurrentUser();
                },
                child: const Text(
                  'Mark all read',
                  style: TextStyle(color: AppColors.primaryBlue, fontSize: 12),
                ),
              ),
            ],
          ),
          body: notifications.isEmpty
              ? Center(
                  child: Text(
                    'No notifications yet.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    final _NotificationVisual visual = _visualForType(n.type);
                    final String timeLabel = n.createdAt == null
                        ? 'Just now'
                        : _relativeLabel(n.createdAt!);

                    return InkWell(
                      onTap: () {
                        if (!n.isRead) {
                          AppDataRepository.markNotificationAsReadForCurrentUser(
                            n.id,
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: _buildNotificationTile(
                        icon: visual.icon,
                        iconColor: visual.color,
                        title: n.title,
                        message: n.message,
                        time: timeLabel,
                        isUnread: !n.isRead,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread
            ? AppColors.primaryBlue.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnread
              ? AppColors.primaryBlue.withValues(alpha: 0.15)
              : Colors.grey.shade100,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isUnread
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _NotificationVisual _visualForType(String type) {
    switch (type) {
      case 'security':
        return const _NotificationVisual(
          Icons.verified_user,
          AppColors.errorRed,
        );
      case 'warning':
        return const _NotificationVisual(
          Icons.warning_amber_rounded,
          AppColors.errorRed,
        );
      case 'reminder':
        return const _NotificationVisual(
          Icons.schedule,
          AppColors.primaryOrange,
        );
      case 'loan':
        return const _NotificationVisual(
          Icons.account_balance,
          AppColors.primaryBlue,
        );
      case 'deposit':
        return const _NotificationVisual(
          Icons.download,
          AppColors.successGreen,
        );
      case 'withdrawal':
        return const _NotificationVisual(Icons.upload, AppColors.errorRed);
      default:
        return const _NotificationVisual(
          Icons.notifications,
          AppColors.primaryBlue,
        );
    }
  }

  String _relativeLabel(DateTime createdAt) {
    final Duration delta = DateTime.now().difference(createdAt);

    if (delta.inSeconds < 60) {
      return 'Just now';
    }
    if (delta.inMinutes < 60) {
      return '${delta.inMinutes} min ago';
    }
    if (delta.inHours < 24) {
      return '${delta.inHours} hr ago';
    }
    if (delta.inDays < 7) {
      return '${delta.inDays} day ago';
    }

    final int weeks = (delta.inDays / 7).floor();
    if (weeks < 5) {
      return '$weeks wk ago';
    }

    final int months = (delta.inDays / 30).floor();
    if (months < 12) {
      return '$months mo ago';
    }

    final int years = (delta.inDays / 365).floor();
    return '$years yr ago';
  }
}

class _NotificationVisual {
  const _NotificationVisual(this.icon, this.color);

  final IconData icon;
  final Color color;
}
