import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';

class AdminLoansPage extends StatefulWidget {
  const AdminLoansPage({super.key});

  @override
  State<AdminLoansPage> createState() => _AdminLoansPageState();
}

class _AdminLoansPageState extends State<AdminLoansPage> {
  String _filterStatus = 'All';
  Timer? _refreshTimer;
  final Map<String, bool> _decisionLoading = <String, bool>{};

  @override
  void initState() {
    super.initState();
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
                    setState(() => _filterStatus = value);
                  },
                ),
              );

              final liveBadges = StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collectionGroup('loanApplications')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildInlineError('Unable to load counts');
                  }

                  final docs = snapshot.data?.docs ?? const [];
                  final pendingCount = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['status'] ?? 'Pending Review') ==
                        'Pending Review';
                  }).length;
                  final approvedCount = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['status'] ?? '') == 'Approved';
                  }).length;
                  final rejectedCount = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['status'] ?? '') == 'Rejected';
                  }).length;

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatBadge('Pending', pendingCount),
                      _buildStatBadge('Approved', approvedCount),
                      _buildStatBadge('Rejected', rejectedCount),
                    ],
                  );
                },
              );

              if (constraints.maxWidth < 860) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    filterDropdown,
                    const SizedBox(height: 12),
                    liveBadges,
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
                      child: liveBadges,
                    ),
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collectionGroup('loanApplications')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Unable to load loan applications. Check Firestore rules/index.',
                        style: TextStyle(color: AppColors.errorRed),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final applications = snapshot.data!.docs
                    .where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['status'] ?? 'Pending Review';
                      if (_filterStatus == 'All') {
                        return true;
                      }
                      return status == _filterStatus;
                    })
                    .toList(growable: false);

                if (applications.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'No loan applications found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
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
                    rows: applications
                        .map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final amountValue =
                              (data['amountValue'] as num?)?.toInt() ?? 0;
                          final createdAt = (data['createdAt'] as Timestamp?)
                              ?.toDate();
                          final loanDocumentId = doc.id;
                          final applicationId =
                              (data['applicationId'] as String?)
                                      ?.trim()
                                      .isNotEmpty ==
                                  true
                              ? (data['applicationId'] as String).trim()
                              : loanDocumentId;
                          final userId = _resolveUserId(
                            data,
                            doc.reference.parent.parent,
                          );
                          final isBusy =
                              _decisionLoading[applicationId] ?? false;
                          final status =
                              (data['status'] as String?) ?? 'Pending Review';

                          return DataRow(
                            cells: [
                              DataCell(Text(applicationId)),
                              DataCell(
                                SizedBox(
                                  width: 190,
                                  child: Text(
                                    _getLoanApplicantLabel(
                                      data,
                                      doc.reference.parent.parent,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(Text(data['loanType'] ?? '-')),
                              DataCell(
                                Text(AppDataRepository.formatUgx(amountValue)),
                              ),
                              DataCell(Text(data['period'] ?? '-')),
                              DataCell(
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    data['purpose'] ?? '-',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(_buildStatusChip(status)),
                              DataCell(Text(_getRelativeTime(createdAt))),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (status == 'Pending Review') ...[
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
                                        onPressed: (isBusy || userId == null)
                                            ? null
                                            : () async {
                                                await _approveLoan(
                                                  applicationId,
                                                  loanDocumentId,
                                                  userId,
                                                  amountValue,
                                                );
                                              },
                                        tooltip: userId == null
                                            ? 'Cannot resolve applicant'
                                            : 'Approve',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.cancel,
                                          color: AppColors.errorRed,
                                        ),
                                        onPressed: (isBusy || userId == null)
                                            ? null
                                            : () async {
                                                await _rejectLoanWithReasonDialog(
                                                  applicationId,
                                                  loanDocumentId,
                                                  userId,
                                                );
                                              },
                                        tooltip: userId == null
                                            ? 'Cannot resolve applicant'
                                            : 'Reject',
                                      ),
                                    ],
                                    IconButton(
                                      icon: const Icon(
                                        Icons.visibility,
                                        color: AppColors.primaryBlue,
                                      ),
                                      onPressed: () => _showLoanDetails(
                                        context,
                                        applicationId,
                                        loanDocumentId,
                                        data,
                                        userId,
                                      ),
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
                );
              },
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

  Widget _buildInlineError(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.errorRed,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  String _getLoanApplicantLabel(
    Map<String, dynamic> loanData,
    DocumentReference? userDoc,
  ) {
    final String name = (loanData['userName'] as String?)?.trim() ?? '';
    final String email = (loanData['userEmail'] as String?)?.trim() ?? '';

    if (name.isNotEmpty && email.isNotEmpty) {
      return '$name\n$email';
    }
    if (email.isNotEmpty) {
      return email;
    }
    if (name.isNotEmpty) {
      return name;
    }

    final userId = _resolveUserId(loanData, userDoc);
    if (userId != null) {
      return 'User ID: $userId';
    }

    return '-';
  }

  String? _resolveUserId(
    Map<String, dynamic> loanData,
    DocumentReference? userDoc,
  ) {
    final String userIdFromLoan = (loanData['userId'] as String?)?.trim() ?? '';
    if (userIdFromLoan.isNotEmpty) {
      return userIdFromLoan;
    }

    final String userIdFromPath = userDoc?.id.trim() ?? '';
    if (userIdFromPath.isNotEmpty) {
      return userIdFromPath;
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

  void _showLoanDetails(
    BuildContext context,
    String appId,
    String loanDocumentId,
    Map<String, dynamic> data,
    String? userId,
  ) {
    final amountValue = (data['amountValue'] as num?)?.toInt() ?? 0;
    final status = (data['status'] as String?) ?? 'Pending Review';

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
              _detailRow('Application ID', appId),
              _detailRow('Applicant', data['userName']?.toString() ?? '-'),
              _detailRow('Email', data['userEmail']?.toString() ?? '-'),
              _detailRow('Phone', data['userPhone']?.toString() ?? '-'),
              _detailRow('Loan Type', data['loanType']?.toString() ?? '-'),
              _detailRow('Amount', AppDataRepository.formatUgx(amountValue)),
              _detailRow('Period', data['period']?.toString() ?? '-'),
              _detailRow('Purpose', data['purpose']?.toString() ?? '-'),
              _detailRow('Status', status),
              const SizedBox(height: 20),
              if (status == 'Pending Review')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (userId != null) {
                            _rejectLoanWithReasonDialog(
                              appId,
                              loanDocumentId,
                              userId,
                            );
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
                          if (userId != null) {
                            _approveLoan(
                              appId,
                              loanDocumentId,
                              userId,
                              amountValue,
                            );
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
    String appId,
    String loanDocumentId,
    String userId,
  ) async {
    final reason = await _promptRejectionReason();
    if (reason == null) {
      return;
    }

    await _rejectLoan(appId, loanDocumentId, userId, reason);
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

  Future<void> _approveLoan(
    String appId,
    String loanDocumentId,
    String userId,
    int amountValue,
  ) async {
    if (mounted) {
      setState(() => _decisionLoading[appId] = true);
    }

    try {
      await AppDataRepository.approveLoanApplication(
        userId,
        appId,
        loanDocumentId: loanDocumentId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Loan approved. ${AppDataRepository.formatUgx(amountValue)} credited to user account.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approving loan: $e')));
    } finally {
      if (mounted) {
        setState(() => _decisionLoading.remove(appId));
      }
    }
  }

  Future<void> _rejectLoan(
    String appId,
    String loanDocumentId,
    String userId,
    String reason,
  ) async {
    if (mounted) {
      setState(() => _decisionLoading[appId] = true);
    }

    try {
      await AppDataRepository.rejectLoanApplication(
        userId,
        appId,
        reason,
        loanDocumentId: loanDocumentId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan rejected successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error rejecting loan: $e')));
    } finally {
      if (mounted) {
        setState(() => _decisionLoading.remove(appId));
      }
    }
  }
}
