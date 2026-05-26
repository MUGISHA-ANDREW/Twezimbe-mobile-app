import 'package:twezimbeapp/core/data/db_constants.dart';

/// Represents a loan product cached in SQLite.
class LoanProductModel {
  const LoanProductModel({
    required this.id,
    required this.name,
    required this.interestRateBps,
    required this.minAmountValue,
    required this.maxAmountValue,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.syncStatus,
  });

  final String id;
  final String name;
  final int interestRateBps;
  final int minAmountValue;
  final int maxAmountValue;
  final String createdAt;
  final String updatedAt;
  final int version;
  final String syncStatus;

  /// Creates a LoanProductModel from a database map.
  factory LoanProductModel.fromMap(Map<String, dynamic> map) {
    return LoanProductModel(
      id: map[DbColumns.id] as String? ?? '',
      name: map['name'] as String? ?? '',
      interestRateBps: (map[DbColumns.interestRateBps] as num?)?.toInt() ?? 0,
      minAmountValue: (map['min_amount_value'] as num?)?.toInt() ?? 0,
      maxAmountValue: (map['max_amount_value'] as num?)?.toInt() ?? 0,
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
      'name': name,
      DbColumns.interestRateBps: interestRateBps,
      'min_amount_value': minAmountValue,
      'max_amount_value': maxAmountValue,
      DbColumns.createdAt: createdAt,
      DbColumns.updatedAt: updatedAt,
      DbColumns.version: version,
      DbColumns.syncStatus: syncStatus,
    };
  }
}
