import 'package:twezimbeapp/core/data/db_constants.dart';

/// Represents a loan persisted in SQLite.
class LoanModel {
  const LoanModel({
    required this.id,
    required this.userId,
    required this.loanId,
    required this.type,
    required this.status,
    required this.amountValue,
    required this.remainingBalanceValue,
    required this.period,
    required this.purpose,
    required this.nextPaymentDate,
    required this.repaymentProgress,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.syncStatus,
  });

  final String id;
  final String userId;
  final String loanId;
  final String type;
  final String status;
  final int amountValue;
  final int remainingBalanceValue;
  final String period;
  final String purpose;
  final String nextPaymentDate;
  final int repaymentProgress;
  final String createdAt;
  final String updatedAt;
  final int version;
  final String syncStatus;

  /// Creates a LoanModel from a database map.
  factory LoanModel.fromMap(Map<String, dynamic> map) {
    return LoanModel(
      id: map[DbColumns.id] as String? ?? '',
      userId: map[DbColumns.userId] as String? ?? '',
      loanId: map[DbColumns.loanId] as String? ?? '',
      type: map['loan_type'] as String? ?? '',
      status: map[DbColumns.status] as String? ?? '',
      amountValue: (map[DbColumns.amountValue] as num?)?.toInt() ?? 0,
      remainingBalanceValue:
          (map[DbColumns.remainingBalanceValue] as num?)?.toInt() ?? 0,
      period: map[DbColumns.period] as String? ?? '',
      purpose: map[DbColumns.purpose] as String? ?? '',
      nextPaymentDate: map[DbColumns.nextPaymentDate] as String? ?? '',
      repaymentProgress:
          (map[DbColumns.repaymentProgress] as num?)?.toInt() ?? 0,
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
      DbColumns.loanId: loanId,
      'loan_type': type,
      DbColumns.status: status,
      DbColumns.amountValue: amountValue,
      DbColumns.remainingBalanceValue: remainingBalanceValue,
      DbColumns.period: period,
      DbColumns.purpose: purpose,
      DbColumns.nextPaymentDate: nextPaymentDate,
      DbColumns.repaymentProgress: repaymentProgress,
      DbColumns.createdAt: createdAt,
      DbColumns.updatedAt: updatedAt,
      DbColumns.version: version,
      DbColumns.syncStatus: syncStatus,
    };
  }
}
