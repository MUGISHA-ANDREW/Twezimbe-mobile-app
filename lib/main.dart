import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twezimbeapp/core/data/db_factory_initializer.dart';
import 'package:twezimbeapp/core/data/local_user_session_store.dart';
import 'package:twezimbeapp/core/notifications/local_notification_service.dart';
import 'package:twezimbeapp/core/data/app_data_repository.dart';
import 'package:twezimbeapp/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/auth/presentation/pages/sign_in_page.dart';
import 'package:twezimbeapp/features/dashboard/presentation/pages/main_layout.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Must be called before any DatabaseHelper access.
  await initializeDatabaseFactory();

  await Supabase.initialize(
    url: 'https://dnbnhqelnxvrhtbazrxt.supabase.co',
    anonKey: 'sb_publishable_erXFel5CNhqEF1Kiips66w_DeW0GAUz',
  );

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

  await LocalNotificationService.initialize();
  runApp(const TwezimbeApp());
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
  bool _isBootstrapAdmin = false;
  bool _isLoading = true;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _listenToAuthChanges();
    _initializeStartup();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _listenToAuthChanges() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (!mounted) return;
      final user = data.session?.user;
      if (user == null) {
        setState(() {
          _isAuthenticated = false;
          _isBootstrapAdmin = false;
        });
        return;
      }

      _handleAuthenticatedUser(user);
      if (mounted) {
        setState(() => _isAuthenticated = true);
      }
    });
  }

  void _handleAuthenticatedUser(User user) {
    _isBootstrapAdmin = _isBootstrapAdminEmail(user.email);
    unawaited(
      AppDataRepository.ensureProfileForCurrentUser(
        email: user.email,
      ).catchError((_) {}),
    );
    unawaited(LocalUserSessionStore.saveUser(user).catchError((_) {}));
  }

  Future<void> _initializeStartup() async {
    try {
      await _resolveInitialAuthState();
    } catch (error) {
      debugPrint('AuthGate startup error: $error');
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
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
    final session = Supabase.instance.client.auth.currentSession;
    final currentUser = session?.user;

    if (currentUser != null) {
      _handleAuthenticatedUser(currentUser);
      if (mounted) setState(() => _isAuthenticated = true);
      return true;
    }

    _isBootstrapAdmin = false;

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
      if (_isBootstrapAdmin) {
        return const AdminDashboardPage();
      }

      return StreamBuilder<AppProfileData>(
        stream: AppDataRepository.watchProfileForCurrentUser(),
        builder: (context, snapshot) {
          final currentUser = Supabase.instance.client.auth.currentUser;
          if (_isBootstrapAdminEmail(currentUser?.email)) {
            return const AdminDashboardPage();
          }

          final profile = snapshot.data;
          if (profile?.isAdmin == true) {
            return const AdminDashboardPage();
          }
          return const MainLayout();
        },
      );
    }

    return const SignInPage();
  }

  bool _isBootstrapAdminEmail(String? email) {
    if (email == null) return false;
    return email.trim().toLowerCase() == 'admin@twezimbe.co.ug';
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
