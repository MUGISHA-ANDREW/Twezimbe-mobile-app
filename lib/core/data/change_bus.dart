import 'dart:async';

/// Broadcasts table-level change events for reactive SQLite streams.
class DatabaseChangeBus {
  DatabaseChangeBus._();

  static final DatabaseChangeBus instance = DatabaseChangeBus._();

  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  /// Emits a change event for the given table name.
  void notify(String table) {
    if (_controller.isClosed) return;
    _controller.add(table);
  }

  /// Stream of table change events.
  Stream<String> get stream => _controller.stream;

  /// Disposes the stream controller.
  Future<void> dispose() async {
    await _controller.close();
  }
}
