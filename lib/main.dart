import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:twezimbeapp/firebase_options.dart';
import 'package:twezimbeapp/core/theme/app_theme.dart';
import 'package:twezimbeapp/features/auth/presentation/pages/sign_in_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      home: const SignInPage(),
    );
  }
}
