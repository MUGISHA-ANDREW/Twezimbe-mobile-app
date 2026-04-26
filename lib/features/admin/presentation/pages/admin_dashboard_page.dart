import 'dart:async';

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
      backgroundColor: const Color(0xFFF2F6FC),
      appBar: isCompact
          ? AppBar(
              title: Text(_titleForIndex(_selectedIndex)),
              backgroundColor: Colors.transparent,
              elevation: 0,
            )
          : null,
      drawer: isCompact
          ? Drawer(
              width: 300,
              backgroundColor: Colors.transparent,
              child: SafeArea(child: _buildNavigationPane(isDrawer: true)),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFDCE8FF).withValues(alpha: 0.45),
              const Color(0xFFF6F9FF),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isCompact
            ? _pages[_selectedIndex]
            : Row(
                children: [
                  SizedBox(width: 280, child: _buildNavigationPane()),
                  Expanded(child: _pages[_selectedIndex]),
                ],
              ),
      ),
    );
  }

  Widget _buildNavigationPane({bool isDrawer = false}) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F2F68), Color(0xFF163F89)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBlue.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 22),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
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
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Twezimbe Management',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12.5,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 14),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                dense: true,
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
          const SizedBox(height: 16),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.28)
              : Colors.transparent,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: isSelected
            ? const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.white,
              )
            : null,
        selected: isSelected,
        onTap: () {
          setState(() => _selectedIndex = index);
          if (closeDrawerOnTap && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      ),
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
  StreamSubscription<int>? _usersCountSubscription;
  StreamSubscription<int>? _totalIncomeSubscription;

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
    _startRealtimeMetricSubscriptions();
  }

  @override
  void dispose() {
    _usersCountSubscription?.cancel();
    _totalIncomeSubscription?.cancel();
    _updateTitleController.dispose();
    _updateMessageController.dispose();
    super.dispose();
  }

  void _startRealtimeMetricSubscriptions() {
    _usersCountSubscription?.cancel();
    _usersCountSubscription = _repository
        .watchTotalUsersCountFromFirebase()
        .listen((totalUsers) {
          if (!mounted) return;
          setState(() {
            _metrics = <String, int>{..._metrics, 'totalUsers': totalUsers};
          });
        });

    _totalIncomeSubscription?.cancel();
    _totalIncomeSubscription = _repository
        .watchTotalIncomeFromFirebase()
        .listen((totalIncome) {
          if (!mounted) return;
          setState(() {
            _metrics = <String, int>{..._metrics, 'totalRevenue': totalIncome};
          });
        });
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
        hint: 'Registered clients',
      ),
      _buildStatCard(
        'Active Loans',
        '$activeLoans',
        Icons.account_balance,
        AppColors.primaryOrange,
        hint: 'In repayment cycle',
      ),
      _buildStatCard(
        'Defaulters',
        '$defaulters',
        Icons.warning_amber_rounded,
        AppColors.errorRed,
        hint: 'Need intervention',
      ),
      _buildStatCard(
        'Total Revenue',
        _formatUgx(totalRevenue),
        Icons.attach_money,
        AppColors.successGreen,
        hint: 'Recovered payments',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(),
          const SizedBox(height: 22),

          if (_error != null)
            _buildLoadError('Unable to load dashboard data: $_error'),
          if (_error != null) const SizedBox(height: 18),

          _buildSectionHeader(
            title: 'Performance Overview',
            subtitle: 'Track platform health at a glance',
            action: OutlinedButton.icon(
              onPressed: _isLoading ? null : _loadDashboard,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh Data'),
            ),
          ),
          const SizedBox(height: 14),

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
          const SizedBox(height: 24),

          _buildSectionHeader(
            title: 'Recent Activities',
            subtitle: 'Latest onboarding and verification activity',
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            child: _recentUsers.isEmpty
                ? _buildInlineEmptyState(
                    icon: _isLoading
                        ? Icons.hourglass_top_rounded
                        : Icons.history_toggle_off_rounded,
                    title: _isLoading
                        ? 'Fetching latest activities...'
                        : 'No recent users found',
                    subtitle: _isLoading
                        ? 'Please wait while we load the latest onboarding events.'
                        : 'New client activity will appear here once users join or update profiles.',
                  )
                : Column(
                    children: _recentUsers
                        .asMap()
                        .entries
                        .map((user) {
                          final item = user.value;
                          return _buildActivityRow(
                            user: item,
                            showDivider: user.key < _recentUsers.length - 1,
                          );
                        })
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(
            title: 'Client Communication',
            subtitle: 'Broadcast updates or message a specific client',
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedAudience,
                  decoration: const InputDecoration(
                    labelText: 'Recipients',
                    prefixIcon: Icon(Icons.group_outlined),
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
                      prefixIcon: Icon(Icons.person_outline),
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
                    prefixIcon: Icon(Icons.title_rounded),
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
                    prefixIcon: Icon(Icons.campaign_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _isSendingUpdate || !canSendSpecific
                        ? null
                        : _sendClientUpdate,
                    icon: _isSendingUpdate
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _isSendingUpdate ? 'Sending...' : 'Send Update',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
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

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15408D), Color(0xFF1E60E2), Color(0xFF3D7BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Admin Control Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Monitor users, manage loans, and communicate with clients from one professional workspace.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE5F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _buildActivityRow({
    required AdminUserModel user,
    required bool showDivider,
  }) {
    final statusColor = _statusColor(user.kycStatus);
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName.isEmpty ? 'Unknown user' : user.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                user.kycStatus,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Color _statusColor(String status) {
    final value = status.trim().toLowerCase();
    if (value == 'kyc verified') return AppColors.successGreen;
    if (value == 'rejected') return AppColors.errorRed;
    return AppColors.primaryOrange;
  }

  Widget _buildInlineEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE5F3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAdminSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    if (!mounted) return;

    final Color backgroundColor = isError
        ? AppColors.errorRed
        : (isSuccess ? AppColors.successGreen : AppColors.primaryBlue);
    final IconData icon = isError
        ? Icons.error_outline_rounded
        : (isSuccess ? Icons.check_circle_outline_rounded : Icons.info_outline);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  Future<void> _sendClientUpdate() async {
    final title = _updateTitleController.text.trim();
    final message = _updateMessageController.text.trim();
    if (title.isEmpty || message.isEmpty) {
      _showAdminSnackBar(
        'Please provide both title and message.',
        isError: true,
      );
      return;
    }

    if (_selectedAudience == 'specific' &&
        (_selectedUserId == null || _selectedUserId!.trim().isEmpty)) {
      _showAdminSnackBar('Please select a specific client.', isError: true);
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
      _showAdminSnackBar(
        'Update sent to $sentCount client(s).',
        isSuccess: true,
      );
      await _loadDashboard();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showAdminSnackBar('Failed to send update: $error', isError: true);
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
    Color color, {
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE5F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
