import 'package:twezimbeapp/core/data/db_constants.dart';

/// Represents a loan application persisted in SQLite.
class LoanApplicationModel {
  const LoanApplicationModel({
    required this.id,
    required this.applicationId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.customerId,
    required this.loanType,
    required this.amountValue,
    required this.period,
    required this.purpose,
    required this.status,
    required this.rejectionReason,
    required this.reviewedBy,
    required this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.syncStatus,
  });

  final String id;
  final String applicationId;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String customerId;
  final String loanType;
  final int amountValue;
  final String period;
  final String purpose;
  final String status;
  final String rejectionReason;
  final String reviewedBy;
  final String reviewedAt;
  final String createdAt;
  final String updatedAt;
  final int version;
  final String syncStatus;

  /// Creates a LoanApplicationModel from a database map.
  factory LoanApplicationModel.fromMap(Map<String, dynamic> map) {
    return LoanApplicationModel(
      id: map[DbColumns.id] as String? ?? '',
      applicationId: map[DbColumns.applicationId] as String? ?? '',
      userId: map[DbColumns.userId] as String? ?? '',
      userName: map['user_name'] as String? ?? '',
      userEmail: map['user_email'] as String? ?? '',
      userPhone: map['user_phone'] as String? ?? '',
      customerId: map[DbColumns.customerId] as String? ?? '',
      loanType: map['loan_type'] as String? ?? '',
      amountValue: (map[DbColumns.amountValue] as num?)?.toInt() ?? 0,
      period: map[DbColumns.period] as String? ?? '',
      purpose: map[DbColumns.purpose] as String? ?? '',
      status: map[DbColumns.status] as String? ?? '',
      rejectionReason: map[DbColumns.rejectionReason] as String? ?? '',
      reviewedBy: map[DbColumns.reviewedBy] as String? ?? '',
      reviewedAt: map[DbColumns.reviewedAt] as String? ?? '',
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
      DbColumns.applicationId: applicationId,
      DbColumns.userId: userId,
      'user_name': userName,
      'user_email': userEmail,
      'user_phone': userPhone,
      DbColumns.customerId: customerId,
      'loan_type': loanType,
      DbColumns.amountValue: amountValue,
      DbColumns.period: period,
      DbColumns.purpose: purpose,
      DbColumns.status: status,
      DbColumns.rejectionReason: rejectionReason,
      DbColumns.reviewedBy: reviewedBy,
      DbColumns.reviewedAt: reviewedAt,
      DbColumns.createdAt: createdAt,
      DbColumns.updatedAt: updatedAt,
      DbColumns.version: version,
      DbColumns.syncStatus: syncStatus,
    };
  }
}
