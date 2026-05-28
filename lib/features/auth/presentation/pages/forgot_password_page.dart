import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twezimbeapp/core/constants/app_timeouts.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/auth/domain/auth_input_validators.dart';
import 'package:twezimbeapp/features/auth/presentation/pages/sign_in_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.lock_reset,
              size: 64,
              color: AppColors.primaryBlue.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 24),
            const Text(
              'Forgot Password?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your registered email address and we will send a password reset link.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Email Address',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _sendPasswordResetEmail(),
              decoration: InputDecoration(
                hintText: 'e.g. user@example.com',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSending ? null : _sendPasswordResetEmail,
              child: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Reset Link'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    FocusScope.of(context).unfocus();

    final validationError = AuthInputValidators.validateEmail(
      _emailController.text,
    );
    if (validationError != null) {
      _showMessage(validationError, isError: true);
      return;
    }

    final email = AuthInputValidators.normalizeEmail(_emailController.text);

    setState(() => _isSending = true);
    try {
      await Supabase.instance.client.auth
          .resetPasswordForEmail(email)
          .timeout(kAppOperationTimeout);
      if (!mounted) return;
      _showSuccessDialog(context);
    } on AuthException catch (e) {
      if (!mounted) return;
      _showMessage(_resetErrorMessage(e), isError: true);
    } on TimeoutException {
      if (!mounted) return;
      _showMessage(
        'Request timed out. Please check your internet connection and try again.',
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        'Unable to send reset link right now. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _resetErrorMessage(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid') && message.contains('email')) {
      return 'The email address is invalid.';
    }
    if (message.contains('too many') || message.contains('rate limit')) {
      return 'Too many attempts. Try again later.';
    }
    if (message.contains('network')) {
      return 'No internet connection. Check your network.';
    }
    return 'Could not send reset link. Please try again.';
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? AppColors.errorRed
              : AppColors.successGreen,
        ),
      );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.successGreen,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Reset Link Sent!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your email inbox and click the password reset link to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    ctx,
                    MaterialPageRoute(builder: (context) => const SignInPage()),
                    (route) => false,
                  );
                },
                child: const Text('Back to Sign In'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
