import 'package:twezimbeapp/core/data/db_constants.dart';

/// Represents a loan repayment persisted in SQLite.
class LoanRepaymentModel {
  const LoanRepaymentModel({
    required this.id,
    required this.loanId,
    required this.userId,
    required this.amountValue,
    required this.method,
    required this.status,
    required this.paidAt,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.syncStatus,
  });

  final String id;
  final String loanId;
  final String userId;
  final int amountValue;
  final String method;
  final String status;
  final String paidAt;
  final String createdAt;
  final String updatedAt;
  final int version;
  final String syncStatus;

  /// Creates a LoanRepaymentModel from a database map.
  factory LoanRepaymentModel.fromMap(Map<String, dynamic> map) {
    return LoanRepaymentModel(
      id: map[DbColumns.id] as String? ?? '',
      loanId: map[DbColumns.loanId] as String? ?? '',
      userId: map[DbColumns.userId] as String? ?? '',
      amountValue: (map[DbColumns.amountValue] as num?)?.toInt() ?? 0,
      method: map[DbColumns.method] as String? ?? '',
      status: map[DbColumns.status] as String? ?? '',
      paidAt: map['paid_at'] as String? ?? '',
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
      DbColumns.loanId: loanId,
      DbColumns.userId: userId,
      DbColumns.amountValue: amountValue,
      DbColumns.method: method,
      DbColumns.status: status,
      'paid_at': paidAt,
      DbColumns.createdAt: createdAt,
      DbColumns.updatedAt: updatedAt,
      DbColumns.version: version,
      DbColumns.syncStatus: syncStatus,
    };
  }
}
