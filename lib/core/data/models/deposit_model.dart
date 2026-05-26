import 'package:twezimbeapp/core/data/db_constants.dart';

/// Represents a deposit persisted in SQLite.
class DepositModel {
  const DepositModel({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.amountValue,
    required this.method,
    required this.status,
    required this.reference,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.syncStatus,
  });

  final String id;
  final String userId;
  final String accountId;
  final int amountValue;
  final String method;
  final String status;
  final String reference;
  final String createdAt;
  final String updatedAt;
  final int version;
  final String syncStatus;

  /// Creates a DepositModel from a database map.
  factory DepositModel.fromMap(Map<String, dynamic> map) {
    return DepositModel(
      id: map[DbColumns.id] as String? ?? '',
      userId: map[DbColumns.userId] as String? ?? '',
      accountId: map[DbColumns.accountId] as String? ?? '',
      amountValue: (map[DbColumns.amountValue] as num?)?.toInt() ?? 0,
      method: map[DbColumns.method] as String? ?? '',
      status: map[DbColumns.status] as String? ?? '',
      reference: map[DbColumns.reference] as String? ?? '',
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
      DbColumns.method: method,
      DbColumns.status: status,
      DbColumns.reference: reference,
      DbColumns.createdAt: createdAt,
      DbColumns.updatedAt: updatedAt,
      DbColumns.version: version,
      DbColumns.syncStatus: syncStatus,
    };
  }
}
