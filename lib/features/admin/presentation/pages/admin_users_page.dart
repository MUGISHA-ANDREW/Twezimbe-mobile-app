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
                  .orderBy('createdAt', descending: true)
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

                var users = snapshot.data!.docs.where((doc) {
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
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primaryBlue
                                      .withValues(alpha: 0.1),
                                  backgroundImage: data['photoUrl'] != null
                                      ? NetworkImage(data['photoUrl'])
                                      : null,
                                  child: data['photoUrl'] == null
                                      ? Text(
                                          (data['fullName'] ?? 'U')[0]
                                              .toString()
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: AppColors.primaryBlue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
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
                                      _showUserDetails(context, data),
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

  void _showUserDetails(BuildContext context, Map<String, dynamic> data) {
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _updateKycStatus(data['email'], 'Rejected');
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
                        _updateKycStatus(data['email'], 'KYC Verified');
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

  Future<void> _updateKycStatus(String? email, String status) async {
    if (email == null) return;

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    for (final doc in query.docs) {
      await doc.reference.update({'kycStatus': status});
    }

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
