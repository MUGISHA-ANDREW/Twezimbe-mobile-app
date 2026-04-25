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
  bool _isMutating = false;
  DateTime? _lastRefreshedAt;

  static const Color _surfaceBorder = Color(0xFFDCE5F3);

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
    setState(() => _lastRefreshedAt = DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(),
          const SizedBox(height: 24),

          if (_lastRefreshedAt != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Updated ${_lastRefreshedAt!.hour.toString().padLeft(2, '0')}:${_lastRefreshedAt!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),

          _buildSectionHeader(
            title: 'Directory Controls',
            subtitle: 'Search, filter, and refresh the user directory',
          ),
          const SizedBox(height: 12),

          _buildSectionCard(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final searchField = TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                );

                final filterDropdown = DropdownButtonFormField<String>(
                  initialValue: _filterStatus,
                  decoration: const InputDecoration(
                    labelText: 'Role Filter',
                    prefixIcon: Icon(Icons.filter_list_rounded),
                  ),
                  items: ['All', 'Admin', 'Client']
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
                    _repository.saveUsersStatusFilter(_filterStatus);
                  },
                );

                final refreshButton = OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _lastRefreshedAt = DateTime.now());
                  },
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text('Refresh'),
                );

                if (constraints.maxWidth < 760) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchField,
                      const SizedBox(height: 12),
                      filterDropdown,
                      const SizedBox(height: 10),
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
                    Expanded(child: searchField),
                    const SizedBox(width: 14),
                    SizedBox(width: 220, child: filterDropdown),
                    const SizedBox(width: 10),
                    refreshButton,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 22),

          _buildSectionHeader(
            title: 'Registered Users',
            subtitle: 'Manage account roles, review profiles, or remove users',
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
            child: StreamBuilder<List<AdminUserModel>>(
              stream: _repository.watchUsersFromFirestore(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final users = (snapshot.data ?? const <AdminUserModel>[])
                    .where((user) {
                      final query = _searchQuery.trim().toLowerCase();
                      final matchesQuery =
                          query.isEmpty ||
                          user.fullName.toLowerCase().contains(query) ||
                          user.email.toLowerCase().contains(query);

                      if (!matchesQuery) {
                        return false;
                      }

                      if (_filterStatus == 'Admin') {
                        return user.isAdmin;
                      }
                      if (_filterStatus == 'Client') {
                        return !user.isAdmin;
                      }
                      return true;
                    })
                    .toList(growable: false);

                if (users.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildInlineEmptyState(
                      icon: Icons.group_off_outlined,
                      title: 'No users found',
                      subtitle:
                          'Try changing your search text or role filter to see more results.',
                    ),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.resolveWith(
                      (_) => const Color(0xFFF4F8FF),
                    ),
                    dividerThickness: 0.8,
                    dataRowMinHeight: 62,
                    dataRowMaxHeight: 72,
                    columns: const [
                      DataColumn(label: Text('User')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: users
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
                                _buildStatusChip(
                                  user.isAdmin ? 'Admin' : 'Client',
                                ),
                              ),
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
                                        Icons.visibility_outlined,
                                        color: AppColors.primaryBlue,
                                      ),
                                      onPressed: () =>
                                          _openUserDetails(context, user: user),
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
                );
              },
            ),
          ),
        ],
      ),
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
              _HeaderIcon(icon: Icons.groups_2_rounded),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'User Administration',
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
            'Manage user access, monitor account roles, and keep the platform secure.',
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

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Admin':
        color = AppColors.successGreen;
        break;
      case 'Client':
        color = AppColors.primaryBlue;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                Icons.delete_outline_rounded,
                color: AppColors.errorRed,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Delete User',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${user.fullName}" from the platform? This action cannot be undone.',
          style: TextStyle(color: Colors.grey.shade700, height: 1.35),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performMutation(() async {
                await _repository.deleteUser(user.id);
                if (mounted) {
                  _showMessage('User removed successfully.', isSuccess: true);
                }
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
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
      if (!mounted) {
        return;
      }

      _showMessage(
        makeAdmin
            ? '${user.fullName} is now an admin'
            : 'Admin privileges removed from ${user.fullName}',
        isSuccess: true,
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
      _showMessage('Operation failed: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
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
