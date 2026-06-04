import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/auth/presentation/pages/sign_in_page.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  User? get _user => Supabase.instance.client.auth.currentUser;

  String get _displayName {
    final meta = _user?.userMetadata;
    final name = meta?['full_name'] as String? ?? '';
    if (name.trim().isNotEmpty) return name.trim();
    final email = _user?.email ?? '';
    return email.isNotEmpty ? email.split('@').first : 'Admin';
  }

  String get _email => _user?.email ?? 'No email';

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2F68), Color(0xFF1E60E2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _displayName.isNotEmpty
                          ? _displayName[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Administrator',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Info section
          const Text(
            'Account Info',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _infoTile(Icons.person_outline, 'Name', _displayName),
          _infoTile(Icons.email_outlined, 'Email', _email),
          _infoTile(
            Icons.shield_outlined,
            'Role',
            'System Administrator',
            valueColor: AppColors.primaryBlue,
          ),
          const SizedBox(height: 24),

          const Text(
            'App Info',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _infoTile(Icons.info_outline, 'App', 'Twezimbe Admin Panel'),
          _infoTile(Icons.code_outlined, 'Version', '1.0.0'),
          const SizedBox(height: 32),

          // Logout button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded, color: AppColors.errorRed),
              label: const Text(
                'Log Out',
                style: TextStyle(
                  color: AppColors.errorRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.errorRed, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE5F3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textMain,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
