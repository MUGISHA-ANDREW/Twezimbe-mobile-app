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
  bool _isLoading = true;
  List<AdminLoanApplicationModel> _allApplications =
      <AdminLoanApplicationModel>[];
  List<AdminLoanApplicationModel> _visibleApplications =
      <AdminLoanApplicationModel>[];
  final Map<String, bool> _decisionLoading = <String, bool>{};

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
    await _refreshLoans();
  }

  Future<void> _refreshLoans() async {
    if (!mounted) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _repository.syncLoanApplicationsFromRemote();
      final allLoans = await _repository.getLoanApplications(
        statusFilter: 'All',
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _allApplications = allLoans;
        _visibleApplications = _applyFilter(allLoans, _filterStatus);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Failed to load loan applications: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    final pendingCount = _allApplications
        .where((item) => item.status == 'Pending Review')
        .length;
    final approvedCount = _allApplications
        .where((item) => item.status == 'Approved')
        .length;
    final rejectedCount = _allApplications
        .where((item) => item.status == 'Rejected')
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Loan Applications',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review and manage loan applications',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final filterDropdown = Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButton<String>(
                  value: _filterStatus,
                  underline: const SizedBox(),
                  isExpanded: true,
                  items: ['All', 'Pending Review', 'Approved', 'Rejected']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _filterStatus = value;
                      _visibleApplications = _applyFilter(
                        _allApplications,
                        _filterStatus,
                      );
                    });
                    _repository.saveLoansStatusFilter(_filterStatus);
                  },
                ),
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
                      child: TextButton.icon(
                        onPressed: _isLoading ? null : _refreshLoans,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ),
                  ],
                );
              }

              return Row(
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
                  TextButton.icon(
                    onPressed: _isLoading ? null : _refreshLoans,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _visibleApplications.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'No loan applications found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
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
                      rows: _visibleApplications
                          .map((loan) {
                            final appId = loan.applicationId;
                            final isBusy = _decisionLoading[appId] ?? false;

                            return DataRow(
                              cells: [
                                DataCell(Text(appId)),
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
                                    loan.loanType.isEmpty ? '-' : loan.loanType,
                                  ),
                                ),
                                DataCell(Text(_formatUgx(loan.amountValue))),
                                DataCell(
                                  Text(loan.period.isEmpty ? '-' : loan.period),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                      loan.purpose.isEmpty ? '-' : loan.purpose,
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
                                      if (loan.status == 'Pending Review') ...[
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
                                                  color: AppColors.successGreen,
                                                ),
                                          onPressed:
                                              isBusy || loan.userId.isEmpty
                                              ? null
                                              : () => _approveLoan(loan),
                                          tooltip: loan.userId.isEmpty
                                              ? 'Cannot resolve applicant'
                                              : 'Approve',
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.cancel,
                                            color: AppColors.errorRed,
                                          ),
                                          onPressed:
                                              isBusy || loan.userId.isEmpty
                                              ? null
                                              : () =>
                                                    _rejectLoanWithReasonDialog(
                                                      loan,
                                                    ),
                                          tooltip: loan.userId.isEmpty
                                              ? 'Cannot resolve applicant'
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
  }

  Widget _buildStatBadge(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.primaryBlue,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
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

  void _showLoanDetails(BuildContext context, AdminLoanApplicationModel loan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Loan Application Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _detailRow('Application ID', loan.applicationId),
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
              const SizedBox(height: 20),
              if (loan.status == 'Pending Review')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (loan.userId.isNotEmpty) {
                            _rejectLoanWithReasonDialog(loan);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.errorRed,
                          side: const BorderSide(color: AppColors.errorRed),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (loan.userId.isNotEmpty) {
                            _approveLoan(loan);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                        ),
                        child: const Text('Approve'),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectLoanWithReasonDialog(
    AdminLoanApplicationModel loan,
  ) async {
    final reason = await _promptRejectionReason();
    if (reason == null) {
      return;
    }

    await _rejectLoan(loan, reason);
  }

  Future<String?> _promptRejectionReason() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject Loan Application'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Enter rejection reason',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  return;
                }
                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return reason;
  }

  Future<void> _approveLoan(AdminLoanApplicationModel loan) async {
    final appId = loan.applicationId;
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
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error approving loan: $e');
    } finally {
      if (mounted) {
        setState(() => _decisionLoading.remove(appId));
      }
    }
  }

  Future<void> _rejectLoan(
    AdminLoanApplicationModel loan,
    String reason,
  ) async {
    final appId = loan.applicationId;
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
      _showMessage('Loan rejected successfully.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error rejecting loan: $e');
    } finally {
      if (mounted) {
        setState(() => _decisionLoading.remove(appId));
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
