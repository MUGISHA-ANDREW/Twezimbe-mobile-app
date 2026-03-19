import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/loans/presentation/pages/apply_loan_page.dart';
import 'package:twezimbeapp/features/notifications/presentation/pages/notifications_page.dart';
import 'package:twezimbeapp/features/transactions/presentation/pages/deposit_page.dart';
import 'package:twezimbeapp/features/transactions/presentation/pages/withdraw_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isBalanceVisible = false;
  bool _isNotificationsPanelOpen = false;

  final List<Map<String, dynamic>> _notifications = [
    {
      'icon': Icons.check_circle,
      'iconColor': const Color(0xFF4CAF50),
      'title': 'Loan Approved',
      'message': 'Your Salary Loan of UGX 1,300,000 has been approved.',
      'time': '10:24 AM',
      'isUnread': true,
    },
    {
      'icon': Icons.payment,
      'iconColor': const Color(0xFFFF9800),
      'title': 'Payment Reminder',
      'message': 'Loan installment of UGX 70,000 is due April 15.',
      'time': '08:00 AM',
      'isUnread': true,
    },
    {
      'icon': Icons.download,
      'iconColor': const Color(0xFF1E60E2),
      'title': 'Deposit Received',
      'message': 'You received UGX 80,000 from Lubega Stephen.',
      'time': 'Yesterday',
      'isUnread': false,
    },
    {
      'icon': Icons.security,
      'iconColor': const Color(0xFFE53935),
      'title': 'Security Alert',
      'message': 'A new device login was detected on your account.',
      'time': 'Yesterday',
      'isUnread': false,
    },
  ];

  int get _unreadCount =>
      _notifications.where((n) => n['isUnread'] == true).length;

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n['isUnread'] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (_isNotificationsPanelOpen) {
                setState(() => _isNotificationsPanelOpen = false);
              }
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(
                              'https://i.pravatar.cc/150?img=47',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hi, Agnes!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'CUS00001',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isNotificationsPanelOpen =
                                    !_isNotificationsPanelOpen;
                              });
                            },
                            icon: const Icon(
                              Icons.notifications_none,
                              color: AppColors.darkBlue,
                            ),
                          ),
                          if (_unreadCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$_unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Account Overview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Premium Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryBlue, AppColors.darkBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Available Balance',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isBalanceVisible = !_isBalanceVisible;
                                });
                              },
                              child: Icon(
                                _isBalanceVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white.withOpacity(0.8),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isBalanceVisible ? 'UGX 2,500,000' : 'UGX ••••••••',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Savings Account',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text(
                    'Quick actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Quick Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _QuickAction(
                        icon: Icons.arrow_downward,
                        label: 'Deposit',
                        color: AppColors.successGreen,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DepositPage(),
                            ),
                          );
                        },
                      ),
                      _QuickAction(
                        icon: Icons.arrow_upward,
                        label: 'Withdraw',
                        color: Colors.redAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WithdrawPage(),
                            ),
                          );
                        },
                      ),
                      _QuickAction(
                        icon: Icons.real_estate_agent,
                        label: 'Get loan',
                        color: AppColors.primaryOrange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ApplyLoanPage(),
                            ),
                          );
                        },
                      ),
                      _QuickAction(
                        icon: Icons.more_horiz,
                        label: 'More',
                        color: AppColors.primaryBlue,
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Transactions List
                  const _TransactionTile(
                    icon: Icons.send,
                    iconColor: Colors.red,
                    iconBgColor: Color(0x1A000000), // Approximate red opacity
                    title: 'Sent to Maliro Stephen',
                    subtitle: 'Transfer • Today, 10:24 AM',
                    amount: '- UGX 100,000',
                    isCredit: false,
                  ),
                  const _TransactionTile(
                    icon: Icons.download,
                    iconColor: AppColors.successGreen,
                    iconBgColor: Color(0x1A4CAF50),
                    title: 'Received from Lubega S',
                    subtitle: 'Cash deposit • Yesterday',
                    amount: '+ UGX 80,000',
                    isCredit: true,
                  ),
                  const _TransactionTile(
                    icon: Icons.credit_card,
                    iconColor: AppColors.primaryBlue,
                    iconBgColor: Color(0x1A1E60E2),
                    title: 'Loan Disbursed',
                    subtitle: 'Salary Loan • 12 Nov',
                    amount: '+ UGX 1,300,000',
                    isCredit: true,
                  ),
                ],
              ),
            ),
          ),
          // Notification dropdown panel
          if (_isNotificationsPanelOpen)
            Positioned(
              top: 64,
              right: 16,
              left: 16,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkBlue,
                              ),
                            ),
                            TextButton(
                              onPressed: _markAllAsRead,
                              child: const Text(
                                'Mark all as read',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                          itemBuilder: (context, index) {
                            final n = _notifications[index];
                            final bool isUnread = n['isUnread'] as bool;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _notifications[index]['isUnread'] = false;
                                });
                              },
                              child: Container(
                                color: isUnread
                                    ? AppColors.primaryBlue.withOpacity(0.04)
                                    : Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: (n['iconColor'] as Color)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        n['icon'] as IconData,
                                        color: n['iconColor'] as Color,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  n['title'] as String,
                                                  style: TextStyle(
                                                    fontWeight: isUnread
                                                        ? FontWeight.bold
                                                        : FontWeight.w500,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              if (isUnread)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: AppColors
                                                            .primaryBlue,
                                                        shape: BoxShape.circle,
                                                      ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            n['message'] as String,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                              height: 1.3,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            n['time'] as String,
                                            style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      InkWell(
                        onTap: () {
                          setState(() => _isNotificationsPanelOpen = false);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsPage(),
                            ),
                          );
                        },
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              'See all notifications',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String amount;
  final bool isCredit;

  const _TransactionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ),
        trailing: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isCredit ? AppColors.successGreen : AppColors.textMain,
          ),
        ),
      ),
    );
  }
}
