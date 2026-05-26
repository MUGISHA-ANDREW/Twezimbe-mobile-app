/// Thrown when a database operation fails unexpectedly.
class DatabaseException implements Exception {
  const DatabaseException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// Thrown when a record cannot be located.
class RecordNotFoundException implements Exception {
  const RecordNotFoundException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when a unique constraint violation occurs.
class DuplicateEntryException implements Exception {
  const DuplicateEntryException(this.message);

  final String message;

  @override
  String toString() => message;
}
