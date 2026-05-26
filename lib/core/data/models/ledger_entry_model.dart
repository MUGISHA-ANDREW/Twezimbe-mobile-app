import 'package:twezimbeapp/core/data/db_constants.dart';

/// Represents a ledger entry persisted in SQLite.
class LedgerEntryModel {
  const LedgerEntryModel({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.amountValue,
    required this.entryType,
    required this.referenceType,
    required this.referenceId,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.syncStatus,
  });

  final String id;
  final String userId;
  final String? accountId;
  final int amountValue;
  final String entryType;
  final String referenceType;
  final String referenceId;
  final String createdAt;
  final String updatedAt;
  final int version;
  final String syncStatus;

  /// Creates a LedgerEntryModel from a database map.
  factory LedgerEntryModel.fromMap(Map<String, dynamic> map) {
    return LedgerEntryModel(
      id: map[DbColumns.id] as String? ?? '',
      userId: map[DbColumns.userId] as String? ?? '',
      accountId: map[DbColumns.accountId] as String?,
      amountValue: (map[DbColumns.amountValue] as num?)?.toInt() ?? 0,
      entryType: map[DbColumns.entryType] as String? ?? '',
      referenceType: map[DbColumns.referenceType] as String? ?? '',
      referenceId: map[DbColumns.referenceId] as String? ?? '',
      createdAt: map[DbColumns.createdAt] as String? ?? '',
      updatedAt: map[DbColumns.updatedAt] as String? ?? '',
      version: (map[DbColumns.version] as num?)?.toInt() ?? 0,
      syncStatus: map[DbColumns.syncStatus] as String? ?? DbSyncStatus.synced,
    );
  }

  /// Converts this model into a database map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      DbColumns.id: id,
      DbColumns.userId: userId,
      DbColumns.accountId: accountId,
      DbColumns.amountValue: amountValue,
      DbColumns.entryType: entryType,
      DbColumns.referenceType: referenceType,
      DbColumns.referenceId: referenceId,
      DbColumns.createdAt: createdAt,
      DbColumns.updatedAt: updatedAt,
      DbColumns.version: version,
      DbColumns.syncStatus: syncStatus,
    };
  }
}
