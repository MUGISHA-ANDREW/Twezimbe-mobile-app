import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:twezimbeapp/core/data/local_user_session_store.dart';
import 'package:twezimbeapp/core/notifications/local_notification_service.dart';
import 'package:twezimbeapp/firebase_options.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/auth/presentation/pages/sign_in_page.dart';
import 'package:twezimbeapp/features/dashboard/presentation/pages/main_layout.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalNotificationService.initialize();
  runApp(const TwezimbeApp());
}

class TwezimbeApp extends StatelessWidget {
  const TwezimbeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Twezimbe Mobile App',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthGatePage(),
    );
  }
}

class AuthGatePage extends StatefulWidget {
  const AuthGatePage({super.key});

  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends State<AuthGatePage> {
  bool? _isAuthenticated;

  @override
  void initState() {
    super.initState();
    _initializeStartup();
  }

  Future<void> _initializeStartup() async {
    final result = await Future.wait<dynamic>([
      _resolveInitialAuthState(),
      Future<void>.delayed(const Duration(seconds: 2)),
    ]);

    if (!mounted) return;
    setState(() {
      _isAuthenticated = result.first as bool;
    });
  }

  Future<bool> _resolveInitialAuthState() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await LocalUserSessionStore.saveUser(currentUser);
      return true;
    }

    final localSession = await LocalUserSessionStore.readSession();
    if (localSession != null && localSession.uid.isNotEmpty) {
      // A local record exists but no Firebase auth user is active.
      await LocalUserSessionStore.clear();
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated == null) {
      return const _SplashScreen();
    }

    if (_isAuthenticated!) {
      return const MainLayout();
    }

    return const SignInPage();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A3A8A), Color(0xFF0A6FD6)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Image(
                        image: AssetImage('assets/branding/launcher_icon.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Text(
                      'Twezimbe',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F326D),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Smart savings for your group',
                  style: TextStyle(
                    color: Color(0xFFD7E6FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 28),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
