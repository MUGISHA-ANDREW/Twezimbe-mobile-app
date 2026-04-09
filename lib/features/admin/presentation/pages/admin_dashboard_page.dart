import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/admin/presentation/pages/admin_users_page.dart';
import 'package:twezimbeapp/features/admin/presentation/pages/admin_loans_page.dart';
import 'package:twezimbeapp/features/auth/presentation/pages/sign_in_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminHomeTab(),
    const AdminUsersPage(),
    const AdminLoansPage(),
  ];

  static const double _compactBreakpoint = 1000;

  @override
  Widget build(BuildContext context) {
    final bool isCompact =
        MediaQuery.sizeOf(context).width < _compactBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isCompact
          ? AppBar(title: Text(_titleForIndex(_selectedIndex)))
          : null,
      drawer: isCompact
          ? Drawer(
              width: 300,
              child: SafeArea(child: _buildNavigationPane(isDrawer: true)),
            )
          : null,
      body: isCompact
          ? _pages[_selectedIndex]
          : Row(
              children: [
                SizedBox(width: 260, child: _buildNavigationPane()),
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
    );
  }

  Widget _buildNavigationPane({bool isDrawer = false}) {
    return Container(
      color: AppColors.darkBlue,
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Twezimbe Management',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 20),
          _buildMenuItem(
            0,
            Icons.dashboard,
            'Dashboard',
            closeDrawerOnTap: isDrawer,
          ),
          _buildMenuItem(
            1,
            Icons.people,
            'Manage Users',
            closeDrawerOnTap: isDrawer,
          ),
          _buildMenuItem(
            2,
            Icons.account_balance,
            'Loan Applications',
            closeDrawerOnTap: isDrawer,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.errorRed,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => _logout(closeDrawerOnTap: isDrawer),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _logout({required bool closeDrawerOnTap}) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (closeDrawerOnTap && navigator.canPop()) {
      navigator.pop();
    }

    messenger.hideCurrentSnackBar();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const SignInPage()),
      (route) => false,
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 1:
        return 'Manage Users';
      case 2:
        return 'Loan Applications';
      default:
        return 'Admin Dashboard';
    }
  }

  Widget _buildMenuItem(
    int index,
    IconData icon,
    String title, {
    required bool closeDrawerOnTap,
  }) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primaryBlue : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.white.withValues(alpha: 0.1),
      onTap: () {
        setState(() => _selectedIndex = index);
        if (closeDrawerOnTap && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}

class AdminHomeTab extends StatelessWidget {
  const AdminHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome back, Admin',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),

          // Stats Cards
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.hasError) {
                return _buildLoadError(
                  'Unable to load dashboard metrics. Check Firestore access.',
                );
              }

              if (!userSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final userDocs = userSnapshot.data!.docs;
              final totalUsers = userDocs.length;
              final totalRevenue = userDocs.fold<int>(0, (runningTotal, doc) {
                final data = doc.data();
                final value = (data['balanceValue'] as num?)?.toInt() ?? 0;
                return runningTotal + value;
              });

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collectionGroup('loanApplications')
                    .snapshots(),
                builder: (context, loanSnapshot) {
                  if (loanSnapshot.hasError) {
                    return _buildLoadError(
                      'Unable to load loan metrics. Check Firestore indexes/rules.',
                    );
                  }

                  final loanDocs = loanSnapshot.data?.docs ?? const [];
                  final activeLoans = loanDocs.where((doc) {
                    final status = (doc.data()['status'] as String?) ?? '';
                    return status == 'Approved' || status == 'Active';
                  }).length;
                  final pendingReviews = loanDocs.where((doc) {
                    final status =
                        (doc.data()['status'] as String?) ?? 'Pending Review';
                    return status == 'Pending Review';
                  }).length;

                  final cards = [
                    _buildStatCard(
                      'Total Users',
                      '$totalUsers',
                      Icons.people,
                      AppColors.primaryBlue,
                    ),
                    _buildStatCard(
                      'Active Loans',
                      '$activeLoans',
                      Icons.account_balance,
                      AppColors.primaryOrange,
                    ),
                    _buildStatCard(
                      'Pending Reviews',
                      '$pendingReviews',
                      Icons.pending_actions,
                      AppColors.errorRed,
                    ),
                    _buildStatCard(
                      'Total Revenue',
                      AppDataRepository.formatUgx(totalRevenue),
                      Icons.attach_money,
                      AppColors.successGreen,
                    ),
                  ];

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 720) {
                        return Column(
                          children: [
                            for (int i = 0; i < cards.length; i++) ...[
                              cards[i],
                              if (i < cards.length - 1)
                                const SizedBox(height: 12),
                            ],
                          ],
                        );
                      }

                      if (constraints.maxWidth < 1180) {
                        final cardWidth = (constraints.maxWidth - 16) / 2;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: cards
                              .map(
                                (card) =>
                                    SizedBox(width: cardWidth, child: card),
                              )
                              .toList(growable: false),
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 16),
                          Expanded(child: cards[1]),
                          const SizedBox(width: 16),
                          Expanded(child: cards[2]),
                          const SizedBox(width: 16),
                          Expanded(child: cards[3]),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 32),

          // Recent Activities
          const Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildLoadError(
                    'Unable to load recent activities. Check Firestore access.',
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs;
                return Column(
                  children: users.map((user) {
                    final data = user.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      title: Text(data['fullName'] ?? 'Unknown'),
                      subtitle: Text(data['email'] ?? ''),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          data['kycStatus'] ?? 'Verified',
                          style: const TextStyle(
                            color: AppColors.successGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadError(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}
