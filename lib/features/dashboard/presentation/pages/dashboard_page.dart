import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/loans/presentation/pages/apply_loan_page.dart';
import 'package:twezimbeapp/features/loans/presentation/pages/loan_calculator_page.dart';
import 'package:twezimbeapp/features/transactions/presentation/pages/deposit_page.dart';
import 'package:twezimbeapp/features/transactions/presentation/pages/withdraw_page.dart';
import 'package:twezimbeapp/features/profile/presentation/pages/profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.optimisticRecentTransaction});

  final AppTransactionData? optimisticRecentTransaction;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isBalanceVisible = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Refresh UI every 30 seconds to update relative time labels
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  String _getGreetingName(AppProfileData profile) {
    // Use profile's fullName (which is editable) - this is the exact username
    if (profile.fullName.trim().isNotEmpty) {
      return profile.fullName.trim();
    }
    // Fallback to email
    final email = _currentUser?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'there';
  }

  String _getRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  AppProfileData get _fallbackProfile {
    final user = _currentUser;
    final email = user?.email ?? '';
    return AppProfileData(
      fullName: email.isNotEmpty ? email.split('@').first :'there',
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
      isAdmin: false,
    );
  }

  List<AppTransactionData> _mergedRecentTransactions(
    List<AppTransactionData> streamedTransactions,
  ) {
    final optimistic = widget.optimisticRecentTransaction;
    if (optimistic == null) return streamedTransactions;

    final exists = streamedTransactions.any(
      (tx) =>
          tx.title == optimistic.title &&
          tx.subtitle == optimistic.subtitle &&
          tx.amount == optimistic.amount &&
          tx.isCredit == optimistic.isCredit,
    );
    if (exists) return streamedTransactions;

    return [optimistic, ...streamedTransactions];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<AppProfileData>(
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
                      notificationSnapshot.data ??
                      const <AppNotificationData>[];
                  final unreadCount = notifications
                      .where((n) => !n.isRead)
                      .length;

                  return CustomScrollView(
                    slivers: [
                      // App Bar
                      SliverAppBar(
                        expandedHeight: 120,
                        floating: false,
                        pinned: true,
                        backgroundColor: AppColors.background,
                        elevation: 0,
                        flexibleSpace: FlexibleSpaceBar(
                          background: Container(
                            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    // Profile Picture
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ProfilePage(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primaryBlue
                                              .withValues(alpha: 0.12),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: profile.photoUrl != null
                                              ? Image.network(
                                                  profile.photoUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return _buildInitials(
                                                          profile.fullName,
                                                        );
                                                      },
                                                )
                                              : _buildInitials(
                                                  profile.fullName,
                                                ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Welcome back,',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _getGreetingName(profile),
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textMain,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                _buildNotificationButton(unreadCount),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Content
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Balance Card
                              _buildBalanceCard(profile),

                              const SizedBox(height: 24),

                              // Quick Actions
                              _buildQuickActionsSection(),

                              const SizedBox(height: 28),

                              // Recent Transactions
                              _buildTransactionsSection(recentTransactions),

                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInitials(String name) {
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton(int unreadCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.notifications_none,
            color: AppColors.darkBlue,
            size: 24,
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppColors.errorRed,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBalanceCard(AppProfileData profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Balance',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isBalanceVisible = !_isBalanceVisible;
                  });
                },
                child: Icon(
                  _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isBalanceVisible ? profile.availableBalance : 'UGX •••••••',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      profile.kycStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  profile.accountType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.add_circle_outline,
                label: 'Deposit',
                color: AppColors.successGreen,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DepositPage(),
                    ),
                  );
                  if (mounted) setState(() {});
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.remove_circle_outline,
                label: 'Withdraw',
                color: AppColors.errorRed,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WithdrawPage(),
                    ),
                  );
                  if (mounted) setState(() {});
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.account_balance,
                label: 'Get Loan',
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
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.calculate_outlined,
                label: 'Calculator',
                color: AppColors.lightBlue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoanCalculatorPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionsSection(
    List<AppTransactionData> recentTransactions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
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
        const SizedBox(height: 12),

        if (recentTransactions.isEmpty)
          _buildEmptyTransactions()
        else
          ...recentTransactions.take(5).map((tx) => _buildTransactionTile(tx)),
      ],
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: AppColors.primaryBlue,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your transaction history will appear here',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(AppTransactionData tx) {
    final iconColor = tx.isCredit ? AppColors.successGreen : AppColors.errorRed;
    // Use dynamic relative time that updates as time passes
    final relativeTime = _getRelativeTime(tx.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  relativeTime,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            '${tx.isCredit ? '+' : '-'}${tx.amount}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: tx.isCredit ? AppColors.successGreen : AppColors.errorRed,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
