import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/admin/data/admin_local_repository.dart';
import 'package:twezimbeapp/features/admin/domain/models/admin_loan_application_model.dart';

class AdminLoansPage extends StatefulWidget {
  const AdminLoansPage({super.key});

  @override
  State<AdminLoansPage> createState() => _AdminLoansPageState();
}

class _AdminLoansPageState extends State<AdminLoansPage> {
  final AdminLocalRepository _repository = AdminLocalRepository();

  String _filterStatus = 'All';
  Timer? _refreshTimer;
  final Map<String, bool> _decisionLoading = <String, bool>{};

  static const Color _surfaceBorder = Color(0xFFDCE5F3);

  @override
  void initState() {
    super.initState();
    _initializePage();
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

  Future<void> _initializePage() async {
    final savedFilter = await _repository.getSavedLoansStatusFilter();
    if (!mounted) {
      return;
    }

    setState(() => _filterStatus = savedFilter);
  }

  Future<void> _refreshLoans() async {
    if (mounted) {
      setState(() {});
    }
  }

  List<AdminLoanApplicationModel> _applyFilter(
    List<AdminLoanApplicationModel> loans,
    String filter,
  ) {
    if (filter == 'All') {
      return loans;
    }
    return loans.where((item) => item.status == filter).toList(growable: false);
  }

  String _getRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'Just now';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    }
    if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminLoanApplicationModel>>(
      stream: _repository.watchLoanApplicationsFromFirestore(),
      builder: (context, snapshot) {
        final allApplications =
            snapshot.data ?? const <AdminLoanApplicationModel>[];
        final visibleApplications = _applyFilter(
          allApplications,
          _filterStatus,
        );

        final pendingCount = allApplications
            .where((item) => item.status == 'Pending')
            .length;
        final approvedCount = allApplications
            .where((item) => item.status == 'Approved')
            .length;
        final rejectedCount = allApplications
            .where((item) => item.status == 'Rejected')
            .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroHeader(),
              const SizedBox(height: 24),

              _buildSectionHeader(
                title: 'Pipeline Controls',
                subtitle: 'Filter submissions and monitor review workload',
              ),
              const SizedBox(height: 12),
              _buildSectionCard(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final filterDropdown = DropdownButtonFormField<String>(
                      initialValue: _filterStatus,
                      decoration: const InputDecoration(
                        labelText: 'Application Status',
                        prefixIcon: Icon(Icons.filter_alt_outlined),
                      ),
                      items: ['All', 'Pending', 'Approved', 'Rejected']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _filterStatus = value;
                        });
                        _repository.saveLoansStatusFilter(_filterStatus);
                      },
                    );

                    final badges = Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatBadge('Pending', pendingCount),
                        _buildStatBadge('Approved', approvedCount),
                        _buildStatBadge('Rejected', rejectedCount),
                      ],
                    );

                    final refreshButton = OutlinedButton.icon(
                      onPressed: _refreshLoans,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh'),
                    );

                    if (constraints.maxWidth < 860) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          filterDropdown,
                          const SizedBox(height: 12),
                          badges,
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: refreshButton,
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 260, child: filterDropdown),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: badges,
                          ),
                        ),
                        const SizedBox(width: 12),
                        refreshButton,
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),

              _buildSectionHeader(
                title: 'Loan Review Queue',
                subtitle: 'Approve, reject, or inspect each application record',
              ),
              const SizedBox(height: 12),

              _buildSectionCard(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _surfaceBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : visibleApplications.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: _buildInlineEmptyState(
                          icon: Icons.assignment_late_outlined,
                          title: 'No loan applications found',
                          subtitle:
                              'There are no submissions for the selected status right now.',
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.resolveWith(
                            (_) => const Color(0xFFF4F8FF),
                          ),
                          dividerThickness: 0.8,
                          dataRowMinHeight: 62,
                          dataRowMaxHeight: 76,
                          columns: const [
                            DataColumn(label: Text('Application ID')),
                            DataColumn(label: Text('Applicant')),
                            DataColumn(label: Text('Loan Type')),
                            DataColumn(label: Text('Amount')),
                            DataColumn(label: Text('Period')),
                            DataColumn(label: Text('Purpose')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: visibleApplications
                              .map((loan) {
                                final appId = _applicationLookupId(loan);
                                final decisionKey =
                                    appId ??
                                    '${loan.userId}_${loan.createdAt?.millisecondsSinceEpoch ?? 0}';
                                final isBusy =
                                    _decisionLoading[decisionKey] ?? false;

                                return DataRow(
                                  cells: [
                                    DataCell(Text(appId ?? '-')),
                                    DataCell(
                                      SizedBox(
                                        width: 190,
                                        child: Text(
                                          _getLoanApplicantLabel(loan),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        loan.loanType.isEmpty
                                            ? '-'
                                            : loan.loanType,
                                      ),
                                    ),
                                    DataCell(
                                      Text(_formatUgx(loan.amountValue)),
                                    ),
                                    DataCell(
                                      Text(
                                        loan.period.isEmpty ? '-' : loan.period,
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 150,
                                        child: Text(
                                          loan.purpose.isEmpty
                                              ? '-'
                                              : loan.purpose,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(_buildStatusChip(loan.status)),
                                    DataCell(
                                      Text(_getRelativeTime(loan.createdAt)),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (loan.status == 'Pending') ...[
                                            IconButton(
                                              icon: isBusy
                                                  ? const SizedBox(
                                                      height: 16,
                                                      width: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                  : const Icon(
                                                      Icons.check_circle,
                                                      color: AppColors
                                                          .successGreen,
                                                    ),
                                              onPressed:
                                                  isBusy ||
                                                      loan.userId.isEmpty ||
                                                      appId == null
                                                  ? null
                                                  : () => _approveLoan(
                                                      loan,
                                                      appId,
                                                    ),
                                              tooltip:
                                                  loan.userId.isEmpty ||
                                                      appId == null
                                                  ? 'Cannot resolve application'
                                                  : 'Approve',
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.cancel,
                                                color: AppColors.errorRed,
                                              ),
                                              onPressed:
                                                  isBusy ||
                                                      loan.userId.isEmpty ||
                                                      appId == null
                                                  ? null
                                                  : () =>
                                                        _rejectLoanWithReasonDialog(
                                                          loan,
                                                          appId,
                                                        ),
                                              tooltip:
                                                  loan.userId.isEmpty ||
                                                      appId == null
                                                  ? 'Cannot resolve application'
                                                  : 'Reject',
                                            ),
                                          ],
                                          IconButton(
                                            icon: const Icon(
                                              Icons.visibility,
                                              color: AppColors.primaryBlue,
                                            ),
                                            onPressed: () =>
                                                _showLoanDetails(context, loan),
                                            tooltip: 'View Details',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              })
                              .toList(growable: false),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _HeaderIcon(icon: Icons.request_quote_rounded),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Loan Operations',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Review every application with confidence and keep approvals consistent.',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
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
    );
  }

  Widget _buildSectionCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    BoxDecoration? decoration,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration:
          decoration ??
          BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _surfaceBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
      child: child,
    );
  }

  Widget _buildStatBadge(String label, int count) {
    final Color color = switch (label) {
      'Pending' => AppColors.primaryOrange,
      'Approved' => AppColors.successGreen,
      'Rejected' => AppColors.errorRed,
      _ => AppColors.primaryBlue,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(color: color, fontSize: 12)),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getLoanApplicantLabel(AdminLoanApplicationModel loan) {
    if (loan.userName.isNotEmpty && loan.userEmail.isNotEmpty) {
      return '${loan.userName}\n${loan.userEmail}';
    }
    if (loan.userEmail.isNotEmpty) {
      return loan.userEmail;
    }
    if (loan.userName.isNotEmpty) {
      return loan.userName;
    }
    if (loan.userId.isNotEmpty) {
      return 'User ID: ${loan.userId}';
    }
    return '-';
  }

  String? _applicationLookupId(AdminLoanApplicationModel loan) {
    if (loan.applicationId.trim().isNotEmpty) {
      return loan.applicationId.trim();
    }
    if (loan.id.trim().isNotEmpty) {
      return loan.id.trim();
    }
    return null;
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Approved':
        color = AppColors.successGreen;
        break;
      case 'Rejected':
        color = AppColors.errorRed;
        break;
      default:
        color = AppColors.primaryOrange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
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
        border: Border.all(color: _surfaceBorder.withValues(alpha: 0.9)),
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

  void _showLoanDetails(BuildContext context, AdminLoanApplicationModel loan) {
    final appId = _applicationLookupId(loan);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _surfaceBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: AppColors.primaryBlue,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Loan Application Details',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow('Application ID', appId ?? '-'),
              _detailRow(
                'Applicant',
                loan.userName.isEmpty ? '-' : loan.userName,
              ),
              _detailRow(
                'Email',
                loan.userEmail.isEmpty ? '-' : loan.userEmail,
              ),
              _detailRow(
                'Phone',
                loan.userPhone.isEmpty ? '-' : loan.userPhone,
              ),
              _detailRow(
                'Loan Type',
                loan.loanType.isEmpty ? '-' : loan.loanType,
              ),
              _detailRow('Amount', _formatUgx(loan.amountValue)),
              _detailRow('Period', loan.period.isEmpty ? '-' : loan.period),
              _detailRow('Purpose', loan.purpose.isEmpty ? '-' : loan.purpose),
              _detailRow('Status', loan.status),
              const SizedBox(height: 16),
              if (loan.status == 'Pending')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          if (loan.userId.isNotEmpty && appId != null) {
                            _rejectLoanWithReasonDialog(loan, appId);
                          }
                        },
                        icon: const Icon(Icons.cancel_outlined),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.errorRed,
                          side: const BorderSide(color: AppColors.errorRed),
                        ),
                        label: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          if (loan.userId.isNotEmpty && appId != null) {
                            _approveLoan(loan, appId);
                          }
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                          foregroundColor: Colors.white,
                        ),
                        label: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _surfaceBorder.withValues(alpha: 0.85)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rejectLoanWithReasonDialog(
    AdminLoanApplicationModel loan,
    String appId,
  ) async {
    final reason = await _promptRejectionReason();
    if (reason == null) {
      return;
    }

    await _rejectLoan(loan, appId, reason);
  }

  Future<String?> _promptRejectionReason() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.report_gmailerrorred_rounded,
                  color: AppColors.errorRed,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Reject Loan Application',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Enter rejection reason',
              prefixIcon: Icon(Icons.comment_outlined),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  return;
                }
                Navigator.of(dialogContext).pop(value);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return reason;
  }

  Future<void> _approveLoan(
    AdminLoanApplicationModel loan,
    String appId,
  ) async {
    if (mounted) {
      setState(() => _decisionLoading[appId] = true);
    }

    try {
      await _repository.approveLoanApplication(
        applicationId: appId,
        userId: loan.userId,
        amountValue: loan.amountValue,
        loanType: loan.loanType,
        period: loan.period,
        purpose: loan.purpose,
      );

      await _refreshLoans();
      if (!mounted) return;
      _showMessage(
        'Loan approved. ${_formatUgx(loan.amountValue)} credited to user account.',
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error approving loan: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _decisionLoading.remove(appId));
      }
    }
  }

  Future<void> _rejectLoan(
    AdminLoanApplicationModel loan,
    String appId,
    String reason,
  ) async {
    if (mounted) {
      setState(() => _decisionLoading[appId] = true);
    }

    try {
      await _repository.rejectLoanApplication(
        applicationId: appId,
        userId: loan.userId,
        reason: reason,
      );

      await _refreshLoans();
      if (!mounted) return;
      _showMessage('Loan rejected successfully.', isSuccess: true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error rejecting loan: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _decisionLoading.remove(appId));
      }
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    if (!mounted) {
      return;
    }

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
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
