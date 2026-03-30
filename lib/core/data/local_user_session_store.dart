import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LocalUserSession {
  const LocalUserSession({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phoneNumber,
    required this.lastAuthenticatedAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final String phoneNumber;
  final String lastAuthenticatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'lastAuthenticatedAt': lastAuthenticatedAt,
    };
  }

  static LocalUserSession fromJson(Map<String, dynamic> json) {
    return LocalUserSession(
      uid: (json['uid'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      displayName: (json['displayName'] as String?) ?? '',
      phoneNumber: (json['phoneNumber'] as String?) ?? '',
      lastAuthenticatedAt: (json['lastAuthenticatedAt'] as String?) ?? '',
    );
  }
}

class LocalUserSessionStore {
  const LocalUserSessionStore._();

  static const String _sessionFileName = 'user_session.json';

  static Future<File> _sessionFile() async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}${Platform.pathSeparator}$_sessionFileName');
  }

  static Future<void> saveUser(User user) async {
    if (kIsWeb) {
      return;
    }

    final file = await _sessionFile();
    final session = LocalUserSession(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      phoneNumber: user.phoneNumber ?? '',
      lastAuthenticatedAt: DateTime.now().toIso8601String(),
    );

    await file.writeAsString(jsonEncode(session.toJson()), flush: true);
  }

  static Future<LocalUserSession?> readSession() async {
    if (kIsWeb) {
      return null;
    }

    final file = await _sessionFile();
    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return null;
      }

      final dynamic decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return LocalUserSession.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveFromCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await clear();
      return;
    }

    await saveUser(user);
  }

  static Future<void> clear() async {
    if (kIsWeb) {
      return;
    }

    final file = await _sessionFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
