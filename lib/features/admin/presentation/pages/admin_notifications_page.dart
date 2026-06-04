import 'package:flutter/material.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/admin/data/admin_local_repository.dart';
import 'package:twezimbeapp/features/admin/domain/models/admin_user_model.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() =>
      _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final _repo = AdminLocalRepository();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  List<AdminUserModel> _allUsers = [];
  String _audience = 'all';
  String? _selectedUserId;
  bool _isSending = false;
  bool _loadingUsers = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    final users = await _repo.getUsers();
    if (mounted) {
      setState(() {
        _allUsers = users;
        if (_selectedUserId == null && users.isNotEmpty) {
          _selectedUserId = users.first.id;
        }
        _loadingUsers = false;
      });
    }
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    if (title.isEmpty || message.isEmpty) {
      _snack('Please enter both title and message.', isError: true);
      return;
    }
    if (_audience == 'specific' &&
        (_selectedUserId == null || _selectedUserId!.isEmpty)) {
      _snack('Please select a recipient.', isError: true);
      return;
    }

    setState(() => _isSending = true);
    try {
      final count = await _repo.sendClientNotification(
        title: title,
        message: message,
        audience: _audience,
        userId: _selectedUserId,
      );
      if (!mounted) return;
      _titleCtrl.clear();
      _messageCtrl.clear();
      _snack('Sent to $count recipient(s).', isSuccess: true);
    } catch (e) {
      if (!mounted) return;
      _snack('Failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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
    final canSend = _audience != 'specific' ||
        (_selectedUserId != null && _selectedUserId!.isNotEmpty);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF15408D), Color(0xFF3D7BFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send Notification',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        'Broadcast messages to clients or specific users.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Compose form
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Compose Message',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 16),

                // Audience
                DropdownButtonFormField<String>(
                  initialValue: _audience,
                  decoration: const InputDecoration(
                    labelText: 'Recipients',
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('All Clients'),
                    ),
                    DropdownMenuItem(
                      value: 'defaulters',
                      child: Text('Defaulters Only'),
                    ),
                    DropdownMenuItem(
                      value: 'specific',
                      child: Text('Specific Client'),
                    ),
                  ],
                  onChanged: _isSending
                      ? null
                      : (v) => setState(() => _audience = v!),
                ),

                if (_audience == 'specific') ...[
                  const SizedBox(height: 12),
                  _loadingUsers
                      ? const LinearProgressIndicator()
                      : DropdownButtonFormField<String>(
                          initialValue: _selectedUserId,
                          decoration: const InputDecoration(
                            labelText: 'Select Client',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          isExpanded: true,
                          items: _allUsers
                              .map(
                                (u) => DropdownMenuItem<String>(
                                  value: u.id,
                                  child: Text(
                                    u.email.isEmpty
                                        ? u.fullName
                                        : '${u.fullName} (${u.email})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _isSending
                              ? null
                              : (v) => setState(() => _selectedUserId = v),
                        ),
                ],

                const SizedBox(height: 12),
                TextField(
                  controller: _titleCtrl,
                  enabled: !_isSending,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Notification Title',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageCtrl,
                  enabled: !_isSending,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    prefixIcon: Icon(Icons.message_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: (_isSending || !canSend) ? null : _send,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(_isSending ? 'Sending…' : 'Send Notification'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Audience guide
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Audience Guide',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _guideRow(
                  Icons.group,
                  'All Clients',
                  'Every registered user receives the notification.',
                  AppColors.primaryBlue,
                ),
                const SizedBox(height: 10),
                _guideRow(
                  Icons.warning_amber_rounded,
                  'Defaulters Only',
                  'Users with overdue loan payments.',
                  AppColors.errorRed,
                ),
                const SizedBox(height: 10),
                _guideRow(
                  Icons.person,
                  'Specific Client',
                  'Choose one individual user to message.',
                  AppColors.primaryOrange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guideRow(IconData icon, String title, String desc, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                desc,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
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
}
