import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:twezimbeapp/core/data/local_user_session_store.dart';
import 'package:twezimbeapp/core/notifications/local_notification_service.dart';
import 'package:twezimbeapp/core/notifications/push_notification_service.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
import 'package:twezimbeapp/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:twezimbeapp/firebase_options.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/auth/presentation/pages/sign_in_page.dart';
import 'package:twezimbeapp/features/dashboard/presentation/pages/main_layout.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeDatabaseFactory();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalNotificationService.initialize();
  await PushNotificationService.initialize();
  runApp(const TwezimbeApp());
}

Future<void> _initializeDatabaseFactory() async {
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
}

class TwezimbeApp extends StatelessWidget {
  const TwezimbeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Twezimbe',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeStartup();
  }

  Future<void> _initializeStartup() async {
    try {
      await _resolveInitialAuthState();
    } catch (error) {
      debugPrint('AuthGate startup error: $error');
      if (mounted) {
        setState(() {
          _isAuthenticated = FirebaseAuth.instance.currentUser != null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _resolveInitialAuthState() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      unawaited(
        AppDataRepository.ensureProfileForCurrentUser(
          email: currentUser.email,
        ).catchError((_) {}),
      );
      unawaited(LocalUserSessionStore.saveUser(currentUser).catchError((_) {}));
      unawaited(
        AppDataRepository.checkAndSendPaymentDueNotification().catchError(
          (_) {},
        ),
      );
      if (mounted) setState(() => _isAuthenticated = true);
      return true;
    }

    try {
      final localSession = await LocalUserSessionStore.readSession();
      if (localSession != null && localSession.uid.isNotEmpty) {
        await LocalUserSessionStore.clear();
      }
    } catch (error) {
      debugPrint('AuthGate local session cleanup failed: $error');
    }

    if (mounted) setState(() => _isAuthenticated = false);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isAuthenticated == null) {
      return const _SplashScreen();
    }

    if (_isAuthenticated!) {
      return StreamBuilder<AppProfileData>(
        stream: AppDataRepository.watchProfileForCurrentUser(),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          // Show admin dashboard if user is admin
          if (profile?.isAdmin == true) {
            return const AdminDashboardPage();
          }
          return const MainLayout();
        },
      );
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
            colors: [Color(0xFF0A3A8A), Color(0xFF0A6FD6), Color(0xFF1E60E2)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Image(
                      image: AssetImage('assets/branding/launcher_icon.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Twezimbe',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Smart savings for your group',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.9),
                    ),
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
