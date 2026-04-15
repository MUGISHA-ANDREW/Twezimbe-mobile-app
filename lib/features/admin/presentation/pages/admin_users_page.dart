import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/admin/data/admin_local_repository.dart';
import 'package:twezimbeapp/features/admin/domain/models/admin_user_model.dart';
import 'package:twezimbeapp/features/admin/presentation/pages/admin_user_details_page.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final AdminLocalRepository _repository = AdminLocalRepository();

  String _searchQuery = '';
  String _filterStatus = 'All';
  bool _isLoading = true;
  bool _isMutating = false;
  List<AdminUserModel> _users = <AdminUserModel>[];
  DateTime? _lastRefreshedAt;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    final savedFilter = await _repository.getSavedUsersStatusFilter();
    if (!mounted) {
      return;
    }

    setState(() => _filterStatus = savedFilter);
    await _refreshUsers(syncRemote: true);

    // Trigger a second refresh shortly after first paint to capture
    // user records written during recent sign-in/signup transitions.
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) {
        return;
      }
      _refreshUsers(syncRemote: false);
    });
  }

  Future<void> _refreshUsers({required bool syncRemote}) async {
    if (!mounted) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (syncRemote) {
        await _repository.syncUsersFromRemote();
      }

      final users = await _repository.getUsers(
        searchQuery: _searchQuery,
        statusFilter: _filterStatus,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _users = users;
        _lastRefreshedAt = DateTime.now();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Failed to load users: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

          if (_lastRefreshedAt != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Updated ${_lastRefreshedAt!.hour.toString().padLeft(2, '0')}:${_lastRefreshedAt!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),

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
                    _repository.saveUsersStatusFilter(_filterStatus);
                    _refreshUsers(syncRemote: false);
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
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _refreshUsers(syncRemote: true),
                        icon: const Icon(Icons.sync),
                        label: const Text('Sync users'),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 16),
                  SizedBox(width: 240, child: filterDropdown),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _refreshUsers(syncRemote: true),
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync users'),
                  ),
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
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _users.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : SingleChildScrollView(
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
                      rows: _users
                          .map((user) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      _buildUserAvatar(user),
                                      const SizedBox(width: 12),
                                      Text(user.fullName),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(user.email.isEmpty ? '-' : user.email),
                                ),
                                DataCell(
                                  Text(
                                    user.phoneNumber.isEmpty
                                        ? '-'
                                        : user.phoneNumber,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    user.customerId.isEmpty
                                        ? '-'
                                        : user.customerId,
                                  ),
                                ),
                                DataCell(_buildStatusChip(user.kycStatus)),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          user.isAdmin
                                              ? Icons.admin_panel_settings
                                              : Icons.supervised_user_circle,
                                          color: user.isAdmin
                                              ? AppColors.primaryBlue
                                              : Colors.grey,
                                        ),
                                        onPressed: _isMutating
                                            ? null
                                            : () => _toggleAdminRole(
                                                context,
                                                user,
                                                !user.isAdmin,
                                              ),
                                        tooltip: user.isAdmin
                                            ? 'Remove Admin'
                                            : 'Make Admin',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.visibility,
                                          color: AppColors.primaryBlue,
                                        ),
                                        onPressed: () => _openUserDetails(
                                          context,
                                          user: user,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: AppColors.errorRed,
                                        ),
                                        onPressed: _isMutating
                                            ? null
                                            : () => _confirmDeleteUser(
                                                context,
                                                user,
                                              ),
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

  void _openUserDetails(BuildContext context, {required AdminUserModel user}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminUserDetailsPage(
          userId: user.id,
          initialUserData: user.toMap(),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(AdminUserModel user) {
    final String fullName = user.fullName;
    final String initials = fullName.isEmpty ? 'U' : fullName[0].toUpperCase();
    final String? photoUrl = user.photoUrl?.trim();

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

  void _confirmDeleteUser(BuildContext context, AdminUserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete user "${user.fullName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performMutation(() async {
                await _repository.deleteUser(user.id);
                await _refreshUsers(syncRemote: true);
              });
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
    AdminUserModel user,
    bool makeAdmin,
  ) async {
    await _performMutation(() async {
      await _repository.toggleAdminRole(user.id, makeAdmin);
      await _refreshUsers(syncRemote: false);
      if (!mounted) {
        return;
      }

      _showMessage(
        makeAdmin
            ? '${user.fullName} is now an admin'
            : 'Admin privileges removed from ${user.fullName}',
      );
    });
  }

  Future<void> _performMutation(Future<void> Function() action) async {
    if (_isMutating) {
      return;
    }

    setState(() => _isMutating = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Operation failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
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
}
