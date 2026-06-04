import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/admin/data/admin_local_repository.dart';

class AdminActiveLoansPage extends StatefulWidget {
  const AdminActiveLoansPage({super.key});

  @override
  State<AdminActiveLoansPage> createState() => _AdminActiveLoansPageState();
}

class _AdminActiveLoansPageState extends State<AdminActiveLoansPage> {
  final _repo = AdminLocalRepository();
  List<Map<String, dynamic>> _loans = [];
  bool _isLoading = false;
  String _filter = 'All';
  final _searchController = TextEditingController();
  String _search = '';
  Set<String> _defaulterIds = {};

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      setState(() => _search = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final loans = await _repo.getAllActiveLoans();
    final defaulterIds = await _repo.getDefaulterUserIds();
    if (mounted) {
      setState(() {
        _loans = loans;
        _defaulterIds = defaulterIds;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _loans.where((l) {
      final status = _str(l['status']).toLowerCase();
      if (_filter == 'Active' && status != 'active') return false;
      if (_filter == 'Overdue' && !_defaulterIds.contains(_str(l['user_id']))) {
        return false;
      }
      if (_filter == 'Paid Off' && status != 'paid off') return false;
      if (_search.isNotEmpty) {
        final userId = _str(l['user_id']).toLowerCase();
        final loanId = _str(l['loan_id']).toLowerCase();
        final type = _str(l['loan_type']).toLowerCase();
        if (!userId.contains(_search) &&
            !loanId.contains(_search) &&
            !type.contains(_search)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  String _str(dynamic v) => v?.toString().trim() ?? '';
  int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(_str(v)) ?? 0;
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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.successGreen;
      case 'paid off':
        return AppColors.primaryBlue;
      case 'rejected':
        return AppColors.errorRed;
      default:
        return AppColors.primaryOrange;
    }
  }

  Future<void> _markPaidOff(String loanId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Paid Off?'),
        content: const Text(
          'This will set the loan status to Paid Off and clear the remaining balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.successGreen,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _repo.markLoanAsPaidOff(loanId);
    _snack('Loan marked as Paid Off.', isSuccess: true);
    await _load();
  }

  void _snack(String msg, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError
              ? AppColors.errorRed
              : isSuccess
                  ? AppColors.successGreen
                  : AppColors.primaryBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filtered;

    return Column(
      children: [
        // Search + filter bar
        Container(
          color: const Color(0xFFF2F6FC),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by loan ID, type, user ID…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: _searchController.clear,
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Active', 'Overdue', 'Paid Off'].map((f) {
                    final sel = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f),
                        selected: sel,
                        selectedColor:
                            AppColors.primaryBlue.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.primaryBlue,
                        labelStyle: TextStyle(
                          color: sel
                              ? AppColors.primaryBlue
                              : Colors.grey.shade600,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) =>
                            setState(() => _filter = f),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : visible.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) => _tile(visible[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _tile(Map<String, dynamic> loan) {
    final loanId = _str(loan['id']);
    final displayId = _str(loan['loan_id']).isNotEmpty
        ? _str(loan['loan_id'])
        : loanId.substring(0, loanId.length.clamp(0, 8));
    final amount = _int(loan['amount_value']);
    final remaining = _int(loan['remaining_balance_value']);
    final progress = _int(loan['repayment_progress']);
    final status = _str(loan['status']);
    final type = _str(loan['loan_type']);
    final period = _str(loan['period']);
    final userId = _str(loan['user_id']);
    final isOverdue = _defaulterIds.contains(userId);
    final statusColor = _statusColor(status);
    final isPaidOff = status.toLowerCase() == 'paid off';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverdue
              ? AppColors.errorRed.withValues(alpha: 0.4)
              : const Color(0xFFDCE5F3),
        ),
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
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isOverdue) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'OVERDUE',
                    style: TextStyle(
                      color: AppColors.errorRed,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                displayId,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.isEmpty ? 'Loan' : type,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Period: $period',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmt(amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textMain,
                    ),
                  ),
                  Text(
                    'Remaining: ${_fmt(remaining)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.errorRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$progress% repaid',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0, 100) / 100,
                        backgroundColor: Colors.grey.shade200,
                        color: AppColors.successGreen,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPaidOff) ...[
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => _markPaidOff(loanId),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Mark Paid'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.successGreen,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 52,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'No loans found',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Loans will appear here once issued',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
