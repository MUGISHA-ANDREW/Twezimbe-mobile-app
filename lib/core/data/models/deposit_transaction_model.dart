import 'package:twezimbeapp/core/data/db_constants.dart';

/// Represents a deposit transaction persisted in SQLite.
class DepositTransactionModel {
  const DepositTransactionModel({
    required this.id,
    required this.depositId,
    required this.userId,
    required this.amountValue,
    required this.entryType,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.syncStatus,
  });

  final String id;
  final String depositId;
  final String userId;
  final int amountValue;
  final String entryType;
  final String createdAt;
  final String updatedAt;
  final int version;
  final String syncStatus;

  /// Creates a DepositTransactionModel from a database map.
  factory DepositTransactionModel.fromMap(Map<String, dynamic> map) {
    return DepositTransactionModel(
      id: map[DbColumns.id] as String? ?? '',
      depositId: map[DbColumns.depositId] as String? ?? '',
      userId: map[DbColumns.userId] as String? ?? '',
      amountValue: (map[DbColumns.amountValue] as num?)?.toInt() ?? 0,
      entryType: map[DbColumns.entryType] as String? ?? '',
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
      DbColumns.depositId: depositId,
      DbColumns.userId: userId,
      DbColumns.amountValue: amountValue,
      DbColumns.entryType: entryType,
      DbColumns.createdAt: createdAt,
      DbColumns.updatedAt: updatedAt,
      DbColumns.version: version,
      DbColumns.syncStatus: syncStatus,
    };
  }
}
