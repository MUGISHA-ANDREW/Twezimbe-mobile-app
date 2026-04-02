import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Side Navigation
          Container(
            width: 260,
            color: AppColors.darkBlue,
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Admin Header
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
                // Menu Items
                _buildMenuItem(0, Icons.dashboard, 'Dashboard'),
                _buildMenuItem(1, Icons.people, 'Manage Users'),
                _buildMenuItem(2, Icons.account_balance, 'Loan Applications'),
                const Spacer(),
                // Logout
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white70),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white70),
                  ),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await FirebaseAuth.instance.signOut();
                    messenger.hideCurrentSnackBar();
                    // Navigate after async gap - capture context before
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const SignInPage()),
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
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
        setState(() {
          _selectedIndex = index;
        });
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
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),

          // Stats Cards
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Users', '1,234', Icons.people, AppColors.primaryBlue)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Active Loans', '456', Icons.account_balance, AppColors.primaryOrange)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Pending Reviews', '23', Icons.pending_actions, AppColors.errorRed)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Total Revenue', 'UGX 12.5M', Icons.attach_money, AppColors.successGreen)),
            ],
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
                        child: const Icon(Icons.person, color: AppColors.primaryBlue),
                      ),
                      title: Text(data['fullName'] ?? 'Unknown'),
                      subtitle: Text(data['email'] ?? ''),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}