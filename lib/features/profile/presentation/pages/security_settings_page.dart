import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  bool _isUpdating = false;

  Future<void> _updateSecuritySetting({
    bool? biometricEnabled,
    bool? twoFactorEnabled,
    bool? transactionAlerts,
    bool? loginAlerts,
  }) async {
    try {
      setState(() => _isUpdating = true);
      await AppDataRepository.updateSecuritySettingsForCurrentUser(
        biometricEnabled: biometricEnabled,
        twoFactorEnabled: twoFactorEnabled,
        transactionAlerts: transactionAlerts,
        loginAlerts: loginAlerts,
      );
    } catch (_) {
      _showMessage('Could not update security setting.');
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null || email.isEmpty) {
      _showMessage('No email found for password reset.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showMessage('Password reset email sent to $email.');
    } on FirebaseAuthException catch (_) {
      _showMessage('Failed to send reset email. Try again later.');
    }
  }

  Future<void> _showLoginActivity() async {
    final user = FirebaseAuth.instance.currentUser;
    final metadata = user?.metadata;
    final creation = metadata?.creationTime?.toLocal().toString() ?? 'Unknown';
    final lastSignIn =
        metadata?.lastSignInTime?.toLocal().toString() ?? 'Unknown';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Login Activity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account created: $creation'),
              const SizedBox(height: 8),
              Text('Last sign in: $lastSignIn'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security Settings'), centerTitle: true),
      body: StreamBuilder<AppSecuritySettingsData>(
        stream: AppDataRepository.watchSecuritySettingsForCurrentUser(),
        builder: (context, snapshot) {
          final settings =
              snapshot.data ?? AppDataRepository.fallbackSecuritySettings();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Authentication',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
                const SizedBox(height: 16),
                _buildToggleTile(
                  Icons.fingerprint,
                  'Biometric Login',
                  'Use fingerprint or face to sign in',
                  settings.biometricEnabled,
                  (val) => _updateSecuritySetting(biometricEnabled: val),
                ),
                _buildToggleTile(
                  Icons.security,
                  'Two-Factor Authentication',
                  'Require OTP for sensitive actions',
                  settings.twoFactorEnabled,
                  (val) => _updateSecuritySetting(twoFactorEnabled: val),
                ),
                _buildToggleTile(
                  Icons.notifications_active,
                  'Transaction Alerts',
                  'Get notified for every transaction',
                  settings.transactionAlerts,
                  (val) => _updateSecuritySetting(transactionAlerts: val),
                ),
                _buildToggleTile(
                  Icons.login,
                  'Login Alerts',
                  'Receive an alert when your account is accessed',
                  settings.loginAlerts,
                  (val) => _updateSecuritySetting(loginAlerts: val),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Account Security',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionTile(
                  Icons.lock_reset,
                  'Reset Password via Email',
                  _sendPasswordReset,
                ),
                _buildActionTile(Icons.devices, 'Manage Devices', () {
                  _showMessage(
                    'Device management will be expanded with server-side session controls.',
                  );
                }),
                _buildActionTile(
                  Icons.history,
                  'Login Activity',
                  _showLoginActivity,
                ),
                if (_isUpdating)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildToggleTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }
}
