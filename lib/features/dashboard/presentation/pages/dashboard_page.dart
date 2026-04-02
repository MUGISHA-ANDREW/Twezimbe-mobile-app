import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/loans/presentation/pages/apply_loan_page.dart';
import 'package:twezimbeapp/features/loans/presentation/pages/loan_calculator_page.dart';
import 'package:twezimbeapp/features/notifications/presentation/pages/notifications_page.dart';
import 'package:twezimbeapp/features/transactions/presentation/pages/deposit_page.dart';
import 'package:twezimbeapp/features/transactions/presentation/pages/withdraw_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.optimisticRecentTransaction});

  final AppTransactionData? optimisticRecentTransaction;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isBalanceVisible = false;
  bool _isNotificationsPanelOpen = false;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  String get _greetingName {
    final displayName = _currentUser?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = _currentUser?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'there';
  }

  AppProfileData get _fallbackProfile {
    final user = _currentUser;
    final email = user?.email ?? '';

    return AppProfileData(
      fullName: _greetingName,
      email: email,
      phoneNumber: user?.phoneNumber ?? 'Not set',
      dateOfBirth: 'Not set',
      nationalId: 'Not set',
      address: 'Not set',
      photoUrl: user?.photoURL,
      customerId: email.isNotEmpty
          ? 'CUST-${email.split('@').first.toUpperCase()}'
          : 'CUST-00000',
      kycStatus: 'KYC Verified',
      accountType: 'Savings Account',
      availableBalance: 'UGX 0',
    );
  }

  List<AppTransactionData> _mergedRecentTransactions(
    List<AppTransactionData> streamedTransactions,
  ) {
    final optimistic = widget.optimisticRecentTransaction;
    if (optimistic == null) {
      return streamedTransactions;
    }

    final exists = streamedTransactions.any(
      (tx) =>
          tx.title == optimistic.title &&
          tx.subtitle == optimistic.subtitle &&
          tx.amount == optimistic.amount &&
          tx.isCredit == optimistic.isCredit,
    );
    if (exists) {
      return streamedTransactions;
    }

    return [optimistic, ...streamedTransactions];
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppProfileData>(
      stream: AppDataRepository.watchProfileForCurrentUser(),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data ?? _fallbackProfile;

        return StreamBuilder<List<AppTransactionData>>(
          stream: AppDataRepository.watchRecentTransactionsForCurrentUser(
            limit: 50,
          ),
          builder: (context, txSnapshot) {
            final recentTransactions = _mergedRecentTransactions(
              txSnapshot.data ?? const <AppTransactionData>[],
            );

            return StreamBuilder<List<AppNotificationData>>(
              stream: AppDataRepository.watchNotificationsForCurrentUser(
                limit: 20,
              ),
              builder: (context, notificationSnapshot) {
                final notifications =
                    notificationSnapshot.data ?? const <AppNotificationData>[];
                final int unreadCount = notifications
                    .where((n) => !n.isRead)
                    .length;

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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: AppColors.primaryBlue
                                            .withValues(alpha: 0.12),
                                        backgroundImage:
                                            profile.photoUrl != null
                                            ? NetworkImage(profile.photoUrl!)
                                            : null,
                                        child: profile.photoUrl == null
                                            ? Text(
                                                profile.fullName.isNotEmpty
                                                    ? profile.fullName[0]
                                                          .toUpperCase()
                                                    : 'U',
                                                style: const TextStyle(
                                                  color: AppColors.primaryBlue,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Welcome, $_greetingName',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            profile.customerId,
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
                                      if (unreadCount > 0)
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
                                              '$unreadCount',
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
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Premium Balance Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primaryBlue,
                                      AppColors.darkBlue,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Available Balance',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                            fontSize: 14,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _isBalanceVisible =
                                                  !_isBalanceVisible;
                                            });
                                          },
                                          child: Icon(
                                            _isBalanceVisible
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: Colors.white.withValues(
                                              alpha: 0.8,
                                            ),
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _isBalanceVisible
                                          ? profile.availableBalance
                                          : 'UGX .........',
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
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            profile.accountType,
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
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Quick Actions
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _QuickAction(
                                    icon: Icons.arrow_downward,
                                    label: 'Deposit',
                                    color: AppColors.successGreen,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const DepositPage(),
                                        ),
                                      );
                                      if (mounted) {
                                        setState(() {});
                                      }
                                    },
                                  ),
                                  _QuickAction(
                                    icon: Icons.arrow_upward,
                                    label: 'Withdraw',
                                    color: Colors.redAccent,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const WithdrawPage(),
                                        ),
                                      );
                                      if (mounted) {
                                        setState(() {});
                                      }
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
                                          builder: (context) =>
                                              const ApplyLoanPage(),
                                        ),
                                      );
                                    },
                                  ),
                                  _QuickAction(
                                    icon: Icons.calculate_outlined,
                                    label: 'Calculator',
                                    color: AppColors.primaryBlue,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LoanCalculatorPage(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                              if (recentTransactions.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        color: Colors.grey.shade400,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'No recent transactions yet',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ...recentTransactions.take(3).map((tx) {
                                  final iconColor = tx.isCredit
                                      ? AppColors.successGreen
                                      : Colors.redAccent;
                                  return _TransactionTile(
                                    icon: tx.isCredit
                                        ? Icons.download
                                        : Icons.send,
                                    iconColor: iconColor,
                                    iconBgColor: iconColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    title: tx.title,
                                    subtitle: tx.subtitle,
                                    amount: tx.amount,
                                    isCredit: tx.isCredit,
                                  );
                                }),
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
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      14,
                                      8,
                                      8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                          onPressed: () {
                                            AppDataRepository.markAllNotificationsAsReadForCurrentUser();
                                          },
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
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      itemCount: notifications.length,
                                      separatorBuilder: (_, __) =>
                                          const Divider(
                                            height: 1,
                                            indent: 16,
                                            endIndent: 16,
                                          ),
                                      itemBuilder: (context, index) {
                                        final n = notifications[index];
                                        final bool isUnread = !n.isRead;
                                        final _NotificationVisual visual =
                                            _visualForType(n.type);
                                        final String timeLabel =
                                            n.createdAt == null
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
                                          child: Container(
                                            color: isUnread
                                                ? AppColors.primaryBlue
                                                      .withValues(alpha: 0.04)
                                                : Colors.transparent,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: visual.color
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    visual.icon,
                                                    color: visual.color,
                                                    size: 18,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              n.title,
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    isUnread
                                                                    ? FontWeight
                                                                          .bold
                                                                    : FontWeight
                                                                          .w500,
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                          ),
                                                          if (isUnread)
                                                            Container(
                                                              width: 8,
                                                              height: 8,
                                                              decoration: const BoxDecoration(
                                                                color: AppColors
                                                                    .primaryBlue,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        n.message,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey
                                                              .shade600,
                                                          fontSize: 12,
                                                          height: 1.3,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        timeLabel,
                                                        style: TextStyle(
                                                          color: Colors
                                                              .grey
                                                              .shade400,
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
                                      setState(
                                        () => _isNotificationsPanelOpen = false,
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const NotificationsPage(),
                                        ),
                                      );
                                    },
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
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
              },
            );
          },
        );
      },
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
                  color: Colors.black.withValues(alpha: 0.04),
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
