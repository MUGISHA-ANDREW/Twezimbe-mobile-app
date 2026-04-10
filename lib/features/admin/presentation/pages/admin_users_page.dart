import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  String _searchQuery = '';
  String _filterStatus = 'All';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage Users',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View and manage registered users',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Search and Filter
          LayoutBuilder(
            builder: (context, constraints) {
              final searchField = TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              );

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
                  items: ['All', 'KYC Verified', 'Pending', 'Rejected']
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
              );

              if (constraints.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchField,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: filterDropdown),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 16),
                  SizedBox(width: 240, child: filterDropdown),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Users Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Unable to load users. Check Firestore permissions/index.',
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

                final docs = snapshot.data!.docs.toList(growable: false)
                  ..sort((a, b) {
                    final aCreatedAt =
                        (a.data() as Map<String, dynamic>)['createdAt']
                            as Timestamp?;
                    final bCreatedAt =
                        (b.data() as Map<String, dynamic>)['createdAt']
                            as Timestamp?;
                    final aMillis = aCreatedAt?.millisecondsSinceEpoch ?? 0;
                    final bMillis = bCreatedAt?.millisecondsSinceEpoch ?? 0;
                    return bMillis.compareTo(aMillis);
                  });

                var users = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['fullName'] ?? '')
                      .toString()
                      .toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final matchesSearch =
                      _searchQuery.isEmpty ||
                      name.contains(_searchQuery) ||
                      email.contains(_searchQuery);

                  final kycStatus = data['kycStatus'] ?? 'Pending';
                  final matchesFilter =
                      _filterStatus == 'All' ||
                      (_filterStatus == 'KYC Verified' &&
                          kycStatus == 'KYC Verified') ||
                      (_filterStatus == 'Pending' &&
                          kycStatus != 'KYC Verified' &&
                          kycStatus != 'Rejected') ||
                      (_filterStatus == 'Rejected' && kycStatus == 'Rejected');

                  return matchesSearch && matchesFilter;
                }).toList();

                if (users.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Phone')),
                      DataColumn(label: Text('Customer ID')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: users.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                _buildUserAvatar(data),
                                const SizedBox(width: 12),
                                Text(data['fullName'] ?? 'Unknown'),
                              ],
                            ),
                          ),
                          DataCell(Text(data['email'] ?? '-')),
                          DataCell(Text(data['phoneNumber'] ?? '-')),
                          DataCell(Text(data['customerId'] ?? '-')),
                          DataCell(
                            _buildStatusChip(data['kycStatus'] ?? 'Pending'),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Admin toggle button
                                IconButton(
                                  icon: Icon(
                                    (data['isAdmin'] as bool?) == true
                                        ? Icons.admin_panel_settings
                                        : Icons.supervised_user_circle,
                                    color: (data['isAdmin'] as bool?) == true
                                        ? AppColors.primaryBlue
                                        : Colors.grey,
                                  ),
                                  onPressed: () => _toggleAdminRole(
                                    context,
                                    doc.id,
                                    data['fullName'],
                                    !((data['isAdmin'] as bool?) ?? false),
                                  ),
                                  tooltip: (data['isAdmin'] as bool?) == true
                                      ? 'Remove Admin'
                                      : 'Make Admin',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.visibility,
                                    color: AppColors.primaryBlue,
                                  ),
                                  onPressed: () =>
                                      _showUserDetails(context, doc.id, data),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: AppColors.errorRed,
                                  ),
                                  onPressed: () => _confirmDeleteUser(
                                    context,
                                    doc.id,
                                    data['fullName'],
                                  ),
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

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'KYC Verified':
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

  void _showUserDetails(
    BuildContext context,
    String userId,
    Map<String, dynamic> data,
  ) {
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
                'User Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _detailRow('Full Name', data['fullName'] ?? '-'),
              _detailRow('Email', data['email'] ?? '-'),
              _detailRow('Phone', data['phoneNumber'] ?? '-'),
              _detailRow('Customer ID', data['customerId'] ?? '-'),
              _detailRow('Address', data['address'] ?? '-'),
              _detailRow('National ID', data['nationalId'] ?? '-'),
              _detailRow('KYC Status', data['kycStatus'] ?? '-'),
              _detailRow('Account Type', data['accountType'] ?? '-'),
              _detailRow(
                'Joined On',
                _formatTimestamp(data['createdAt'] as Timestamp?),
              ),
              const SizedBox(height: 6),
              _buildExtendedUserData(userId),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateKycStatus(userId, 'Rejected');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorRed,
                        side: const BorderSide(color: AppColors.errorRed),
                      ),
                      child: const Text('Reject KYC'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateKycStatus(userId, 'KYC Verified');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                      ),
                      child: const Text('Approve KYC'),
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

  Widget _buildUserAvatar(Map<String, dynamic> data) {
    final String fullName = (data['fullName'] ?? 'U').toString();
    final String initials = fullName.isEmpty ? 'U' : fullName[0].toUpperCase();
    final String? photoUrl = (data['photoUrl'] as String?)?.trim();

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
      ),
      child: ClipOval(
        child: photoUrl == null || photoUrl.isEmpty
            ? Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildExtendedUserData(String userId) {
    return FutureBuilder<Map<String, String>>(
      future: _loadUserInsights(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }

        final details = snapshot.data;
        if (details == null) {
          return Text(
            'Unable to load linked user data.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 24),
            const Text(
              'Linked Data Overview',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _detailRow('Loan Applications', details['loanApplications'] ?? '0'),
            _detailRow('Transactions', details['transactions'] ?? '0'),
            _detailRow('Notifications', details['notifications'] ?? '0'),
            _detailRow(
              'Active Loan Status',
              details['activeLoanStatus'] ?? '-',
            ),
            _detailRow(
              'Outstanding Balance',
              details['outstandingBalance'] ?? 'UGX 0',
            ),
            _detailRow('Next Payment Date', details['nextPaymentDate'] ?? '-'),
          ],
        );
      },
    );
  }

  Future<Map<String, String>> _loadUserInsights(String userId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    final results = await Future.wait([
      userRef.collection('loanApplications').get(),
      userRef.collection('transactions').get(),
      userRef.collection('notifications').get(),
      userRef.collection('loans').doc('active').get(),
    ]);

    final loanApps = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final transactions = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final notifications = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final activeLoan = results[3] as DocumentSnapshot<Map<String, dynamic>>;
    final activeLoanData = activeLoan.data() ?? const <String, dynamic>{};

    return <String, String>{
      'loanApplications': '${loanApps.size}',
      'transactions': '${transactions.size}',
      'notifications': '${notifications.size}',
      'activeLoanStatus':
          (activeLoanData['status'] as String?)?.trim().isNotEmpty == true
          ? (activeLoanData['status'] as String)
          : 'None',
      'outstandingBalance':
          'UGX ${(activeLoanData['remainingBalanceValue'] as num?)?.toInt() ?? 0}',
      'nextPaymentDate':
          (activeLoanData['nextPaymentDate'] as String?)?.trim().isNotEmpty ==
              true
          ? (activeLoanData['nextPaymentDate'] as String)
          : 'N/A',
    };
  }

  String _formatTimestamp(Timestamp? value) {
    if (value == null) {
      return '-';
    }
    final date = value.toDate();
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
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

  Future<void> _updateKycStatus(String userId, String status) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'kycStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('KYC status updated to $status')));
  }

  void _confirmDeleteUser(
    BuildContext context,
    String userId,
    String? userName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete user "$userName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .delete();
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('User deleted successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAdminRole(
    BuildContext context,
    String userId,
    String? userName,
    bool makeAdmin,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'isAdmin': makeAdmin,
      }, SetOptions(merge: true));

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            makeAdmin
                ? '$userName is now an admin'
                : 'Admin privileges removed from $userName',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error updating admin role: $e')),
      );
    }
  }
}
