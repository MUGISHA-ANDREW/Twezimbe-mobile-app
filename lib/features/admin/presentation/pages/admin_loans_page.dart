import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';

class AdminLoansPage extends StatefulWidget {
  const AdminLoansPage({super.key});

  @override
  State<AdminLoansPage> createState() => _AdminLoansPageState();
}

class _AdminLoansPageState extends State<AdminLoansPage> {
  String _filterStatus = 'All';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
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
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
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

          // Filter
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButton<String>(
                  value: _filterStatus,
                  underline: const SizedBox(),
                  items: ['All', 'Pending Review', 'Approved', 'Rejected']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _filterStatus = value!;
                    });
                  },
                ),
              ),
              const Spacer(),
              _buildStatBadge('Pending', _getPendingCount()),
              const SizedBox(width: 8),
              _buildStatBadge('Approved', _getApprovedCount()),
              const SizedBox(width: 8),
              _buildStatBadge('Rejected', _getRejectedCount()),
            ],
          ),
          const SizedBox(height: 24),

          // Loans Table
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
                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                var applications = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'Pending Review';
                  if (_filterStatus == 'All') return true;
                  return status == _filterStatus;
                }).toList();

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
                      DataColumn(label: Text('User Email')),
                      DataColumn(label: Text('Loan Type')),
                      DataColumn(label: Text('Amount')),
                      DataColumn(label: Text('Period')),
                      DataColumn(label: Text('Purpose')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: applications.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final amountValue =
                          (data['amountValue'] as num?)?.toInt() ?? 0;
                      final createdAt = (data['createdAt'] as Timestamp?)
                          ?.toDate();

                      return DataRow(
                        cells: [
                          DataCell(Text(data['applicationId'] ?? doc.id)),
                          DataCell(
                            Text(_getUserEmail(doc.reference.parent.parent)),
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
                          DataCell(
                            _buildStatusChip(
                              data['status'] ?? 'Pending Review',
                            ),
                          ),
                          DataCell(Text(_getRelativeTime(createdAt))),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (data['status'] == 'Pending Review') ...[
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check_circle,
                                      color: AppColors.successGreen,
                                    ),
                                    onPressed: () async {
                                      final parent =
                                          doc.reference.parent.parent;
                                      if (parent != null) {
                                        await _approveLoan(
                                          doc.id,
                                          parent.path,
                                          amountValue,
                                        );
                                      }
                                    },
                                    tooltip: 'Approve',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.cancel,
                                      color: AppColors.errorRed,
                                    ),
                                    onPressed: () {
                                      final parent =
                                          doc.reference.parent.parent;
                                      if (parent != null) {
                                        _updateLoanStatus(
                                          doc.id,
                                          parent.path,
                                          'Rejected',
                                        );
                                      }
                                    },
                                    tooltip: 'Reject',
                                  ),
                                ],
                                IconButton(
                                  icon: const Icon(
                                    Icons.visibility,
                                    color: AppColors.primaryBlue,
                                  ),
                                  onPressed: () =>
                                      _showLoanDetails(context, doc.id, data),
                                  tooltip: 'View Details',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
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

  int _getPendingCount() {
    // This would be calculated from the actual data
    return 23;
  }

  int _getApprovedCount() {
    return 456;
  }

  int _getRejectedCount() {
    return 12;
  }

  String _getUserEmail(DocumentReference? userDoc) {
    if (userDoc == null) return '-';
    // This is a simplified approach - in production you'd query the user doc
    return 'User';
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
    Map<String, dynamic> data,
  ) {
    final amountValue = (data['amountValue'] as num?)?.toInt() ?? 0;

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
              _detailRow('Loan Type', data['loanType'] ?? '-'),
              _detailRow('Amount', AppDataRepository.formatUgx(amountValue)),
              _detailRow('Period', data['period'] ?? '-'),
              _detailRow('Purpose', data['purpose'] ?? '-'),
              _detailRow('Status', data['status'] ?? 'Pending Review'),
              const SizedBox(height: 20),
              if (data['status'] == 'Pending Review')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Would need to pass the correct user path
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
                          // Would need to pass the correct user path
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

  Future<void> _updateLoanStatus(
    String appId,
    String userPath,
    String status,
  ) async {
    try {
      final userDoc = FirebaseFirestore.instance.doc(userPath);
      final loanDoc = userDoc.collection('loanApplications').doc(appId);

      await loanDoc.update({'status': status});

      // Also update the active loan
      await userDoc.collection('loans').doc('active').update({
        'status': status,
      });

      // Add notification for user
      await AppDataRepository.addNotificationForCurrentUser(
        title: status == 'Approved' ? 'Loan Approved' : 'Loan Rejected',
        message: status == 'Approved'
            ? 'Your loan application has been approved!'
            : 'Your loan application has been rejected. Please contact support.',
        type: 'loan',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Loan $status successfully')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating loan status: $e')));
    }
  }

  Future<void> _approveLoan(
    String appId,
    String userPath,
    int amountValue,
  ) async {
    try {
      final userDoc = FirebaseFirestore.instance.doc(userPath);
      final loanDoc = userDoc.collection('loanApplications').doc(appId);

      await loanDoc.update({'status': 'Approved'});

      // Update active loan status
      await userDoc.collection('loans').doc('active').update({
        'status': 'Active',
      });

      // Credit the loan amount to user's balance
      if (amountValue > 0) {
        await userDoc.set({
          'balanceValue': FieldValue.increment(amountValue),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Create a transaction record for the loan credit
        await userDoc.collection('transactions').doc().set({
          'title': 'Loan Disbursed',
          'subtitle': 'Loan approved and credited to account',
          'amountValue': amountValue,
          'isCredit': true,
          'createdAt': Timestamp.now(),
          'createdAtServer': FieldValue.serverTimestamp(),
        });
      }

      // Add notification for user
      await AppDataRepository.addNotificationForUser(
        userId: userDoc.id,
        title: 'Loan Approved',
        message:
            'Your loan of ${AppDataRepository.formatUgx(amountValue)} has been approved and credited to your account!',
        type: 'loan',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Loan approved! ${AppDataRepository.formatUgx(amountValue)} credited to user balance.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error approving loan: $e')));
    }
  }
}
