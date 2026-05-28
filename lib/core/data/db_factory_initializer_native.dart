import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> initializeDatabaseFactory() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // Android / iOS: sqflite uses the native library — no init needed.
}
