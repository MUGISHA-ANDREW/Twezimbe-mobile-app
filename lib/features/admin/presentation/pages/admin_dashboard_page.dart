import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/admin/data/admin_local_repository.dart';
import 'package:twezimbeapp/features/admin/domain/models/admin_user_model.dart';
import 'package:twezimbeapp/features/admin/presentation/pages/admin_users_page.dart';
import 'package:twezimbeapp/features/admin/presentation/pages/admin_loans_page.dart';
import 'package:twezimbeapp/features/admin/presentation/pages/admin_active_loans_page.dart';
import 'package:twezimbeapp/features/admin/presentation/pages/admin_create_loan_page.dart';
import 'package:twezimbeapp/features/admin/presentation/pages/admin_loan_products_page.dart';
import 'package:twezimbeapp/features/admin/presentation/pages/admin_transactions_page.dart';
import 'package:twezimbeapp/features/admin/presentation/pages/admin_reports_page.dart';
import 'package:twezimbeapp/features/admin/presentation/pages/admin_notifications_page.dart';
import 'package:twezimbeapp/features/admin/presentation/pages/admin_profile_page.dart';

// ─── Loans hub (tabbed) ───────────────────────────────────────────────────────

class _AdminLoansHub extends StatelessWidget {
  const _AdminLoansHub();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F6FC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF2F6FC),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'Loans',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryBlue,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Applications'),
              Tab(text: 'Active Loans'),
              Tab(text: 'Create Loan'),
              Tab(text: 'Products'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminLoansPage(),
            AdminActiveLoansPage(),
            AdminCreateLoanPage(),
            AdminLoanProductsPage(),
          ],
        ),
      ),
    );
  }
}

// ─── Finance hub (tabbed) ─────────────────────────────────────────────────────

class _AdminFinanceHub extends StatelessWidget {
  const _AdminFinanceHub();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F6FC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF2F6FC),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'Finance',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          bottom: const TabBar(
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryBlue,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Transactions'),
              Tab(text: 'Reports'),
              Tab(text: 'Broadcast'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminTransactionsPage(),
            AdminReportsPage(),
            AdminNotificationsPage(),
          ],
        ),
      ),
    );
  }
}

// ─── Root dashboard with BottomNavigationBar ──────────────────────────────────

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(Icons.dashboard_rounded, Icons.dashboard_outlined, 'Home'),
    _NavItem(Icons.people_rounded, Icons.people_outlined, 'Users'),
    _NavItem(Icons.account_balance, Icons.account_balance_outlined, 'Loans'),
    _NavItem(Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Finance'),
    _NavItem(Icons.person_rounded, Icons.person_outlined, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FC),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _AdminHomeScaffold(),
          _AdminUsersScaffold(),
          _AdminLoansHub(),
          _AdminFinanceHub(),
          _AdminProfileScaffold(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final selected = _selectedIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedIndex = i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryBlue.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected ? item.activeIcon : item.icon,
                            color: selected
                                ? AppColors.primaryBlue
                                : Colors.grey.shade500,
                            size: 24,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: selected
                                  ? AppColors.primaryBlue
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  const _NavItem(this.activeIcon, this.icon, this.label);
}

// ─── Home scaffold ────────────────────────────────────────────────────────────

class _AdminHomeScaffold extends StatelessWidget {
  const _AdminHomeScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F6FC),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
      ),
      body: const AdminHomeTab(),
    );
  }
}

// ─── Users scaffold ───────────────────────────────────────────────────────────

class _AdminUsersScaffold extends StatelessWidget {
  const _AdminUsersScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F6FC),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Manage Users',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
      ),
      body: const AdminUsersPage(),
    );
  }
}

// ─── Profile scaffold ─────────────────────────────────────────────────────────

class _AdminProfileScaffold extends StatelessWidget {
  const _AdminProfileScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F6FC),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
      ),
      body: const AdminProfilePage(),
    );
  }
}

// ─── AdminHomeTab (unchanged content) ────────────────────────────────────────

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
        .watchTotalUsersCount()
        .listen((totalUsers) {
          if (!mounted) return;
          setState(
            () => _metrics = <String, int>{..._metrics, 'totalUsers': totalUsers},
          );
        });

    _totalIncomeSubscription?.cancel();
    _totalIncomeSubscription = _repository
        .watchTotalIncome()
        .listen((totalIncome) {
          if (!mounted) return;
          setState(
            () =>
                _metrics = <String, int>{..._metrics, 'totalRevenue': totalIncome},
          );
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
      if (!mounted) return;
      setState(() {
        _metrics = metrics;
        _recentUsers = recentUsers;
        _allUsers = allUsers;
        if (_selectedAudience == 'specific') {
          final exists = _allUsers.any((u) => u.id == _selectedUserId);
          if (!exists) {
            _selectedUserId =
                _allUsers.isNotEmpty ? _allUsers.first.id : null;
          }
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      _buildStatCard('Total Users', '$totalUsers', Icons.people,
          AppColors.primaryBlue, hint: 'Registered clients'),
      _buildStatCard('Active Loans', '$activeLoans', Icons.account_balance,
          AppColors.primaryOrange, hint: 'In repayment cycle'),
      _buildStatCard('Defaulters', '$defaulters',
          Icons.warning_amber_rounded, AppColors.errorRed,
          hint: 'Need intervention'),
      _buildStatCard('Total Revenue', _formatUgx(totalRevenue),
          Icons.attach_money, AppColors.successGreen,
          hint: 'Recovered payments'),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(),
          const SizedBox(height: 20),

          if (_error != null) ...[
            _buildLoadError('Unable to load data: $_error'),
            const SizedBox(height: 16),
          ],

          _buildSectionHeader(
            title: 'Performance Overview',
            subtitle: 'Track platform health at a glance',
            action: OutlinedButton.icon(
              onPressed: _isLoading ? null : _loadDashboard,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ),
          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 500) {
                return Column(
                  children: cards
                      .asMap()
                      .entries
                      .map((e) => Padding(
                            padding: EdgeInsets.only(
                              bottom: e.key < cards.length - 1 ? 12 : 0,
                            ),
                            child: e.value,
                          ))
                      .toList(),
                );
              }
              final w = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    cards.map((c) => SizedBox(width: w, child: c)).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(
            title: 'Recent Signups',
            subtitle: 'Latest client registrations',
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            child: _recentUsers.isEmpty
                ? _buildInlineEmptyState(
                    icon: _isLoading
                        ? Icons.hourglass_top_rounded
                        : Icons.history_toggle_off_rounded,
                    title: _isLoading
                        ? 'Loading…'
                        : 'No recent users found',
                    subtitle: _isLoading
                        ? 'Please wait.'
                        : 'New clients will appear here.',
                  )
                : Column(
                    children: _recentUsers
                        .asMap()
                        .entries
                        .map(
                          (e) => _buildActivityRow(
                            user: e.value,
                            showDivider: e.key < _recentUsers.length - 1,
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(
            title: 'Quick Notification',
            subtitle: 'Broadcast or message clients',
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
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('All Clients'),
                    ),
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
                      : (v) {
                          if (v == null) return;
                          setState(() {
                            _selectedAudience = v;
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
                    isExpanded: true,
                    items: _allUsers
                        .map(
                          (u) => DropdownMenuItem<String>(
                            value: u.id,
                            child: Text(
                              u.email.isEmpty
                                  ? u.fullName
                                  : '${u.fullName} (${u.email})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _isSendingUpdate
                        ? null
                        : (v) => setState(() => _selectedUserId = v),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _updateTitleController,
                  enabled: !_isSendingUpdate,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _updateMessageController,
                  enabled: !_isSendingUpdate,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    prefixIcon: Icon(Icons.campaign_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: (_isSendingUpdate || !canSendSpecific)
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
                      _isSendingUpdate ? 'Sending…' : 'Send',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
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
    final userName = Supabase.instance.client.auth.currentUser
            ?.userMetadata?['full_name'] as String? ??
        Supabase.instance.client.auth.currentUser?.email?.split('@').first ??
        'Admin';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15408D), Color(0xFF1E60E2), Color(0xFF3D7BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
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
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Control Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Welcome, $userName',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE5F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isEmpty ? 'Unknown' : user.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                    ),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  user.kycStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(color: Colors.grey.shade200, height: 1),
      ],
    );
  }

  Color _statusColor(String status) {
    final v = status.trim().toLowerCase();
    if (v == 'kyc verified') return AppColors.successGreen;
    if (v == 'rejected') return AppColors.errorRed;
    return AppColors.primaryOrange;
  }

  Widget _buildInlineEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAdminSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? AppColors.errorRed
              : (isSuccess ? AppColors.successGreen : AppColors.primaryBlue),
          content: Text(message),
        ),
      );
  }

  Future<void> _sendClientUpdate() async {
    final title = _updateTitleController.text.trim();
    final message = _updateMessageController.text.trim();
    if (title.isEmpty || message.isEmpty) {
      _showAdminSnackBar('Please provide both title and message.', isError: true);
      return;
    }
    if (_selectedAudience == 'specific' &&
        (_selectedUserId == null || _selectedUserId!.isEmpty)) {
      _showAdminSnackBar('Please select a client.', isError: true);
      return;
    }

    setState(() => _isSendingUpdate = true);
    try {
      final count = await _repository.sendClientNotification(
        title: title,
        message: message,
        audience: _selectedAudience,
        userId: _selectedUserId,
      );
      if (!mounted) return;
      _updateTitleController.clear();
      _updateMessageController.clear();
      _showAdminSnackBar('Sent to $count client(s).', isSuccess: true);
    } catch (e) {
      if (!mounted) return;
      _showAdminSnackBar('Failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSendingUpdate = false);
    }
  }

  String _formatUgx(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final idxFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buffer.write(',');
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE5F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadError(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
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
