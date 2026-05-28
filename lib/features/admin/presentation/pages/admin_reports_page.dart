import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/admin/data/admin_local_repository.dart';
import 'package:twezimbeapp/features/admin/domain/models/admin_user_model.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final _repo = AdminLocalRepository();
  Map<String, dynamic> _report = {};
  List<AdminUserModel> _defaulters = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final report = await _repo.getReportData();
    final defaulterIds = await _repo.getDefaulterUserIds();
    final allUsers = await _repo.getUsers();
    final defaulterUsers = allUsers
        .where((u) => defaulterIds.contains(u.id))
        .toList();
    if (mounted) {
      setState(() {
        _report = report;
        _defaulters = defaulterUsers;
        _isLoading = false;
      });
    }
  }

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final from = s.length - i;
      buf.write(s[i]);
      if (from > 1 && from % 3 == 1) buf.write(',');
    }
    return 'UGX ${buf.toString()}';
  }

  int _int(String key) => (_report[key] as int?) ?? 0;

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Financial Reports',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Summary cards
                  _sectionLabel('Portfolio Overview'),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: [
                      _metricCard(
                        'Total Deposits',
                        _fmt(_int('totalDeposits')),
                        Icons.arrow_downward_rounded,
                        AppColors.successGreen,
                      ),
                      _metricCard(
                        'Total Withdrawals',
                        _fmt(_int('totalWithdrawals')),
                        Icons.arrow_upward_rounded,
                        AppColors.errorRed,
                      ),
                      _metricCard(
                        'Loans Issued',
                        _fmt(_int('totalLoansIssued')),
                        Icons.account_balance_outlined,
                        AppColors.primaryBlue,
                      ),
                      _metricCard(
                        'Repayments',
                        _fmt(_int('totalRepayments')),
                        Icons.payments_outlined,
                        AppColors.primaryOrange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Outstanding
                  _card(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.pending_actions_outlined,
                            color: AppColors.primaryBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Outstanding Balance',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _fmt(_int('outstandingBalance')),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const Text(
                                'Total remaining across all active loans',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Defaulters
                  _sectionLabel('Defaulters (${_defaulters.length})'),
                  const SizedBox(height: 10),
                  _defaulters.isEmpty
                      ? _card(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: AppColors.successGreen,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'No defaulters — all loans are current.',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : _card(
                          child: Column(
                            children: _defaulters.asMap().entries.map((e) {
                              final u = e.value;
                              return Column(
                                children: [
                                  if (e.key > 0)
                                    Divider(
                                      color: Colors.grey.shade100,
                                      height: 1,
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor:
                                              AppColors.errorRed.withValues(
                                                alpha: 0.12,
                                              ),
                                          child: Text(
                                            u.fullName.isNotEmpty
                                                ? u.fullName[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: AppColors.errorRed,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                u.fullName.isEmpty
                                                    ? 'Unknown'
                                                    : u.fullName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textMain,
                                                ),
                                              ),
                                              Text(
                                                u.email,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (u.phoneNumber.isNotEmpty &&
                                                  u.phoneNumber != 'Not set')
                                                Text(
                                                  u.phoneNumber,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.errorRed
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Overdue',
                                            style: TextStyle(
                                              color: AppColors.errorRed,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                ],
              ),
            ),
          );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.textMain,
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE5F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE5F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
