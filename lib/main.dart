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
  late final Future<bool> _authCheck;

  @override
  void initState() {
    super.initState();
    _authCheck = _resolveInitialAuthState();
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
    return FutureBuilder<bool>(
      future: _authCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isAuthenticated = snapshot.data ?? false;
        if (isAuthenticated) {
          return const MainLayout();
        }
        return const SignInPage();
      },
    );
  }
}
