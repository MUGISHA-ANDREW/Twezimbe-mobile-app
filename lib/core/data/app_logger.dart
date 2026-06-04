import 'package:logger/logger.dart';

/// Shared logger for data layer diagnostics.
class AppLogger {
  AppLogger._();

  static final Logger instance = Logger();
}
