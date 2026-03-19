import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:twezimbeapp/features/dashboard/presentation/pages/main_layout.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (!_acceptedTerms) {
      _showMessage('Please accept terms to continue.');
      return;
    }
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Email and password fields are required.');
      return;
    }
    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }
    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (phone.isNotEmpty) {
        await credential.user?.updateDisplayName(phone);
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'SignUp FirebaseAuthException code=${e.code} message=${e.message}',
      );
      _showMessage(_authErrorMessage(e));
    } catch (e) {
      debugPrint('SignUp unknown exception: $e');
      _showMessage('Sign up failed. Please check your internet and try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'That email is already in use.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled in Firebase Console.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'invalid-api-key':
      case 'app-not-authorized':
        return 'Firebase API key/app config is invalid. Re-run FlutterFire configure.';
      case 'unauthorized-domain':
        return kIsWeb
            ? 'This web domain is not authorized in Firebase Auth settings.'
            : 'This app domain is not authorized.';
      default:
        return e.message == null || e.message!.trim().isEmpty
            ? 'Could not create account (${e.code}).'
            : '${e.message} (${e.code})';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.spa,
                      size: 50,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Twezimbe',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F326D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Join us today!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              _buildLabel('Phone Number'),
              _buildTextField(
                hint: 'eg 0770000000',
                keyboardType: TextInputType.phone,
                controller: _phoneController,
              ),
              const SizedBox(height: 16),

              _buildLabel('Email'),
              _buildTextField(
                hint: 'Your email address',
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
              ),
              const SizedBox(height: 16),

              _buildLabel('Password'),
              _buildTextField(
                hint: 'Your password',
                isPassword: true,
                obscure: _obscurePassword,
                controller: _passwordController,
                onToggleVisibility: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              const SizedBox(height: 16),

              _buildLabel('Confirm Password'),
              _buildTextField(
                hint: 'Confirm your password',
                isPassword: true,
                obscure: _obscurePassword,
                controller: _confirmPasswordController,
                onToggleVisibility: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              const SizedBox(height: 24),

              Center(
                child: Column(
                  children: [
                    IconButton(
                      iconSize: 48,
                      icon: const Icon(
                        Icons.fingerprint,
                        color: Color(0xFFF99D2A),
                      ),
                      onPressed: () {},
                    ),
                    Text(
                      'Enable Biometric Login',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (val) {
                      setState(() => _acceptedTerms = val ?? false);
                    },
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 13,
                        ),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms of Services and Privacy Policy.',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF99D2A),
                ),
                onPressed: _isLoading ? null : _signUp,
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue'),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Have an Account? ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  // TextField with outline border and filled background
  Widget _buildTextField({
    required String hint,
    TextEditingController? controller,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword && obscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: const Color.fromARGB(255, 66, 66, 66),
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility : Icons.visibility_off,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
      ),
    );
  }
}
