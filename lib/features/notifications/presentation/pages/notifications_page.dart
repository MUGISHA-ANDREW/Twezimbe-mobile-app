import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Mark all read',
              style: TextStyle(color: AppColors.primaryBlue, fontSize: 12),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildSectionHeader('Today'),
          _buildNotificationTile(
            icon: Icons.check_circle,
            iconColor: AppColors.successGreen,
            title: 'Loan Approved',
            message:
                'Your Salary Loan application of UGX 1,300,000 has been approved and disbursed to your account.',
            time: '10:24 AM',
            isUnread: true,
          ),
          _buildNotificationTile(
            icon: Icons.payment,
            iconColor: AppColors.primaryOrange,
            title: 'Payment Reminder',
            message:
                'Your loan installment of UGX 70,000 is due on April 15, 2026. Please ensure sufficient balance.',
            time: '08:00 AM',
            isUnread: true,
          ),
          _buildSectionHeader('Yesterday'),
          _buildNotificationTile(
            icon: Icons.download,
            iconColor: AppColors.primaryBlue,
            title: 'Deposit Received',
            message:
                'You received UGX 80,000 from Lubega Stephen via mobile money.',
            time: '02:30 PM',
            isUnread: false,
          ),
          _buildNotificationTile(
            icon: Icons.security,
            iconColor: AppColors.errorRed,
            title: 'Security Alert',
            message:
                'A new device login was detected on your account. If this was not you, please contact support immediately.',
            time: '11:15 AM',
            isUnread: false,
          ),
          _buildSectionHeader('Earlier'),
          _buildNotificationTile(
            icon: Icons.campaign,
            iconColor: AppColors.primaryBlue,
            title: 'New Feature Available',
            message:
                'You can now set up automatic loan repayments via mobile money. Go to Settings to enable.',
            time: 'Nov 10',
            isUnread: false,
          ),
          _buildNotificationTile(
            icon: Icons.send,
            iconColor: Colors.red,
            title: 'Transfer Successful',
            message:
                'Your transfer of UGX 100,000 to Maliro Stephen was completed successfully.',
            time: 'Nov 8',
            isUnread: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
          fontSize: 13,
        ),
      ),
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
            ? AppColors.primaryBlue.withOpacity(0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnread
              ? AppColors.primaryBlue.withOpacity(0.15)
              : Colors.grey.shade100,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
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
}
