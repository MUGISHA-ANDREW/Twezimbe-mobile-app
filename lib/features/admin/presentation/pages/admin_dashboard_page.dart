import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/admin/data/admin_local_repository.dart';
import 'package:twezimbeapp/features/admin/domain/models/admin_user_model.dart';
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

class AdminHomeTab extends StatefulWidget {
  const AdminHomeTab({super.key});

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> {
  final AdminLocalRepository _repository = AdminLocalRepository();
  final TextEditingController _updateTitleController = TextEditingController();
  final TextEditingController _updateMessageController =
      TextEditingController();

  bool _isLoading = false;
  bool _isSendingUpdate = false;
  String? _error;
  String _selectedAudience = 'all';
  String? _selectedUserId;
  Map<String, int> _metrics = const <String, int>{
    'totalUsers': 0,
    'activeLoans': 0,
    'defaulters': 0,
    'totalRevenue': 0,
  };
  List<AdminUserModel> _recentUsers = <AdminUserModel>[];
  List<AdminUserModel> _allUsers = <AdminUserModel>[];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void dispose() {
    _updateTitleController.dispose();
    _updateMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _repository.syncUsersFromRemote();
      await _repository.syncLoanApplicationsFromRemote();
      final metrics = await _repository.getDashboardMetrics();
      final recentUsers = await _repository.getRecentUsers(limit: 5);
      final allUsers = await _repository.getUsers();
      if (!mounted) {
        return;
      }

      setState(() {
        _metrics = metrics;
        _recentUsers = recentUsers;
        _allUsers = allUsers;
        if (_selectedAudience == 'specific') {
          final selectedExists = _allUsers.any((u) => u.id == _selectedUserId);
          if (!selectedExists) {
            _selectedUserId = _allUsers.isNotEmpty ? _allUsers.first.id : null;
          }
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalUsers = _metrics['totalUsers'] ?? 0;
    final activeLoans = _metrics['activeLoans'] ?? 0;
    final defaulters = _metrics['defaulters'] ?? 0;
    final totalRevenue = _metrics['totalRevenue'] ?? 0;
    final canSendSpecific =
        _selectedAudience != 'specific' ||
        (_selectedUserId != null && _selectedUserId!.trim().isNotEmpty);

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
        'Defaulters',
        '$defaulters',
        Icons.warning_amber_rounded,
        AppColors.errorRed,
      ),
      _buildStatCard(
        'Total Revenue',
        _formatUgx(totalRevenue),
        Icons.attach_money,
        AppColors.successGreen,
      ),
    ];

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

          if (_error != null)
            _buildLoadError('Unable to load dashboard data: $_error'),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 720) {
                return Column(
                  children: [
                    for (int i = 0; i < cards.length; i++) ...[
                      cards[i],
                      if (i < cards.length - 1) const SizedBox(height: 12),
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
                      .map((card) => SizedBox(width: cardWidth, child: card))
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
          ),
          const SizedBox(height: 32),

          // Recent Activities
          Row(
            children: [
              const Text(
                'Recent Activities',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _isLoading ? null : _loadDashboard,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: _recentUsers.isEmpty
                ? Text(
                    _isLoading
                        ? 'Fetching latest activities...'
                        : 'No recent users found.',
                    style: TextStyle(color: Colors.grey.shade600),
                  )
                : Column(
                    children: _recentUsers
                        .map((user) {
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            title: Text(
                              user.fullName.isEmpty ? 'Unknown' : user.fullName,
                            ),
                            subtitle: Text(user.email),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.successGreen.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user.kycStatus,
                                style: const TextStyle(
                                  color: AppColors.successGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Client Communication',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedAudience,
                  decoration: const InputDecoration(
                    labelText: 'Recipients',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Clients')),
                    DropdownMenuItem(
                      value: 'defaulters',
                      child: Text('Defaulters Only'),
                    ),
                    DropdownMenuItem(
                      value: 'specific',
                      child: Text('Specific Client'),
                    ),
                  ],
                  onChanged: _isSendingUpdate
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _selectedAudience = value;
                            if (_selectedAudience == 'specific' &&
                                (_selectedUserId == null ||
                                    !_allUsers.any(
                                      (u) => u.id == _selectedUserId,
                                    ))) {
                              _selectedUserId = _allUsers.isNotEmpty
                                  ? _allUsers.first.id
                                  : null;
                            }
                          });
                        },
                ),
                if (_selectedAudience == 'specific') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUserId,
                    decoration: const InputDecoration(
                      labelText: 'Client',
                      border: OutlineInputBorder(),
                    ),
                    items: _allUsers
                        .map(
                          (user) => DropdownMenuItem<String>(
                            value: user.id,
                            child: Text(
                              user.email.isEmpty
                                  ? user.fullName
                                  : '${user.fullName} (${user.email})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: _isSendingUpdate
                        ? null
                        : (value) => setState(() => _selectedUserId = value),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _updateTitleController,
                  enabled: !_isSendingUpdate,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Update Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _updateMessageController,
                  enabled: !_isSendingUpdate,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Update Message',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _isSendingUpdate || !canSendSpecific
                        ? null
                        : _sendClientUpdate,
                    icon: _isSendingUpdate
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      _isSendingUpdate ? 'Sending...' : 'Send Update',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendClientUpdate() async {
    final title = _updateTitleController.text.trim();
    final message = _updateMessageController.text.trim();
    if (title.isEmpty || message.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide both title and message.')),
      );
      return;
    }

    if (_selectedAudience == 'specific' &&
        (_selectedUserId == null || _selectedUserId!.trim().isEmpty)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a specific client.')),
      );
      return;
    }

    setState(() => _isSendingUpdate = true);
    try {
      final sentCount = await _repository.sendClientNotification(
        title: title,
        message: message,
        audience: _selectedAudience,
        userId: _selectedUserId,
      );
      if (!mounted) {
        return;
      }

      _updateMessageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update sent to $sentCount client(s).')),
      );
      await _loadDashboard();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send update: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSendingUpdate = false);
      }
    }
  }

  String _formatUgx(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final idxFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return 'UGX ${buffer.toString()}';
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
