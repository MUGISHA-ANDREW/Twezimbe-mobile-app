import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:twezimbeapp/core/data/database_helper.dart';
import 'package:twezimbeapp/features/admin/domain/models/admin_loan_application_model.dart';
import 'package:twezimbeapp/features/admin/domain/models/admin_notification_model.dart';
import 'package:twezimbeapp/features/admin/domain/models/admin_transaction_model.dart';
import 'package:twezimbeapp/features/admin/domain/models/admin_user_model.dart';

class AdminLocalRepository {
  AdminLocalRepository._();

  static final AdminLocalRepository _instance = AdminLocalRepository._();
  factory AdminLocalRepository() => _instance;

  static const String _usersStatusFilterKey =
      'admin_users_status_filter_preference';
  static const String _loanStatusFilterKey =
      'admin_loans_status_filter_preference';

  final DatabaseHelper _db = DatabaseHelper();

  Future<String> getSavedUsersStatusFilter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usersStatusFilterKey) ?? 'All';
  }

  Future<void> saveUsersStatusFilter(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersStatusFilterKey, value);
  }

  Future<String> getSavedLoansStatusFilter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_loanStatusFilterKey) ?? 'All';
  }

  Future<void> saveLoansStatusFilter(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loanStatusFilterKey, value);
  }

  Future<void> syncUsersFromRemote() async {
    // SQLite-only mode: no remote source to sync.
  }

  Future<List<AdminUserModel>> getUsers({
    String searchQuery = '',
    String statusFilter = 'All',
  }) async {
    final rows = await _db.getAllUsersForAdmin();
    var users = rows.map(AdminUserModel.fromSqlMap).toList(growable: false);

    final normalizedQuery = searchQuery.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty) {
      users = users
          .where((user) {
            return user.fullName.toLowerCase().contains(normalizedQuery) ||
                user.email.toLowerCase().contains(normalizedQuery);
          })
          .toList(growable: false);
    }

    users = users
        .where((user) {
          if (statusFilter == 'All') {
            return true;
          }
          if (statusFilter == 'KYC Verified') {
            return user.kycStatus == 'KYC Verified';
          }
          if (statusFilter == 'Rejected') {
            return user.kycStatus == 'Rejected';
          }
          if (statusFilter == 'Pending') {
            return user.kycStatus != 'KYC Verified' &&
                user.kycStatus != 'Rejected';
          }
          return true;
        })
        .toList(growable: false);

    return users;
  }

  Future<void> updateKycStatus(String userId, String status) async {
    final now = DateTime.now().toIso8601String();
    await _db.updateUser(userId, {'kycStatus': status, 'updatedAt': now});
  }

  Future<void> toggleAdminRole(String userId, bool makeAdmin) async {
    final now = DateTime.now().toIso8601String();
    await _db.updateUser(userId, {
      'isAdmin': makeAdmin ? 1 : 0,
      'updatedAt': now,
    });
  }

  Future<void> deleteUser(String userId) async {
    await _db.deleteUserRelatedData(userId);
  }

  Future<void> syncLoanApplicationsFromRemote() async {
    // SQLite-only mode: no remote source to sync.
  }

  Future<List<AdminLoanApplicationModel>> getLoanApplications({
    String statusFilter = 'All',
  }) async {
    final rows = await _db.getAllLoanApplications();
    var apps = rows
        .map(AdminLoanApplicationModel.fromSqlMap)
        .toList(growable: false);

    if (statusFilter != 'All') {
      apps = apps
          .where((app) => app.status == statusFilter)
          .toList(growable: false);
    }

    return apps;
  }

  Future<AdminUserModel?> getUserById(String userId) async {
    final row = await _db.getUser(userId);
    if (row == null) {
      return null;
    }
    return AdminUserModel.fromSqlMap(row);
  }

  Future<void> syncUserCollectionsFromRemote(String userId) async {
    // SQLite-only mode: no remote source to sync.
  }

  Future<Map<String, int>> getDashboardMetrics() async {
    final totalUsers = await _db.getTotalUsersCount();
    final activeLoans = await _db.getActiveLoansCount();
    final defaulters = await getDefaultersCount();
    final totalRevenue = await _db.getTotalUserBalances();
    return <String, int>{
      'totalUsers': totalUsers,
      'activeLoans': activeLoans,
      'defaulters': defaulters,
      'totalRevenue': totalRevenue,
    };
  }

  Future<int> getDefaultersCount() async {
    final defaulterIds = await getDefaulterUserIds();
    return defaulterIds.length;
  }

  Future<Set<String>> getDefaulterUserIds() async {
    final rows = await _db.getAllLoansForAdmin();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final defaulterIds = <String>{};

    for (final row in rows) {
      final status = _string(row['status']).toLowerCase();
      if (status != 'active' && status != 'approved') {
        continue;
      }

      final remaining = _int(row['remainingBalanceValue']);
      if (remaining <= 0) {
        continue;
      }

      final dueDate = _parseFlexibleDate(_string(row['nextPaymentDate']));
      if (dueDate == null) {
        continue;
      }

      final normalizedDue = DateTime(dueDate.year, dueDate.month, dueDate.day);
      if (normalizedDue.isBefore(today)) {
        final userId = _string(row['userId']);
        if (userId.isNotEmpty) {
          defaulterIds.add(userId);
        }
      }
    }

    return defaulterIds;
  }

  Future<int> sendClientNotification({
    required String title,
    required String message,
    required String audience,
    String? userId,
  }) async {
    final cleanTitle = title.trim();
    final cleanMessage = message.trim();
    if (cleanTitle.isEmpty || cleanMessage.isEmpty) {
      throw ArgumentError('Title and message are required.');
    }

    final allUsers = await _db.getAllUsersForAdmin();
    final allUserIds = allUsers
        .map((row) => _string(row['id']))
        .where((id) => id.isNotEmpty)
        .toSet();

    Set<String> recipients;
    if (audience == 'specific') {
      final selected = (userId ?? '').trim();
      if (selected.isEmpty) {
        throw ArgumentError('Please select a recipient.');
      }
      if (!allUserIds.contains(selected)) {
        throw StateError('Selected recipient does not exist.');
      }
      recipients = <String>{selected};
    } else if (audience == 'defaulters') {
      recipients = await getDefaulterUserIds();
    } else {
      recipients = allUserIds;
    }

    if (recipients.isEmpty) {
      return 0;
    }

    final createdAt = DateTime.now();
    final createdAtIso = createdAt.toIso8601String();
    final sortedRecipients = recipients.toList()..sort();

    for (int i = 0; i < sortedRecipients.length; i++) {
      final recipientId = sortedRecipients[i];
      await _db.insertNotification({
        'id': 'notif_admin_${createdAt.microsecondsSinceEpoch}_$i',
        'userId': recipientId,
        'title': cleanTitle,
        'message': cleanMessage,
        'type': 'admin_update',
        'isRead': 0,
        'createdAt': createdAtIso,
      });
    }

    return sortedRecipients.length;
  }

  Future<List<AdminUserModel>> getRecentUsers({int limit = 5}) async {
    final rows = await _db.getRecentUsersForAdmin(limit: limit);
    return rows.map(AdminUserModel.fromSqlMap).toList(growable: false);
  }

  Future<void> approveLoanApplication({
    required String applicationId,
    required String userId,
    required int amountValue,
    required String loanType,
    required String period,
    required String purpose,
  }) async {
    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    await _db.updateLoanApplication(applicationId, {
      'status': 'Approved',
      'rejectionReason': null,
      'reviewedBy': 'local_admin',
      'reviewedAt': nowIso,
      'updatedAt': nowIso,
    });

    final existingLoan = await _db.getActiveLoan(userId);
    if (existingLoan == null) {
      await _db.insertLoan({
        'id': 'active_$userId',
        'userId': userId,
        'loanId': 'LN${now.millisecondsSinceEpoch}',
        'type': loanType,
        'status': 'Active',
        'amountValue': amountValue,
        'remainingBalanceValue': amountValue,
        'period': period,
        'purpose': purpose,
        'nextPaymentDate': now.add(const Duration(days: 30)).toIso8601String(),
        'repaymentProgress': 0,
        'createdAt': nowIso,
        'updatedAt': nowIso,
      });
    } else {
      final currentRemaining = _int(existingLoan['remainingBalanceValue']);
      final currentPrincipal = _int(existingLoan['amountValue']);
      await _db.updateLoan(existingLoan['id'].toString(), {
        'remainingBalanceValue': currentRemaining + amountValue,
        'amountValue': currentPrincipal + amountValue,
        'updatedAt': nowIso,
      });
    }

    final user = await _db.getUser(userId);
    final currentBalance = _int(user?['balanceValue']);
    await _db.updateUser(userId, {
      'balanceValue': currentBalance + amountValue,
      'updatedAt': nowIso,
    });

    await _db.insertTransaction({
      'id': 'tx_${now.microsecondsSinceEpoch}',
      'userId': userId,
      'title': 'Loan Approved',
      'subtitle': '$loanType approved and credited',
      'amountValue': amountValue,
      'isCredit': 1,
      'createdAt': nowIso,
    });

    await _db.insertNotification({
      'id': 'notif_${now.microsecondsSinceEpoch}',
      'userId': userId,
      'title': 'Loan Approved',
      'message':
          'Your loan application ($applicationId) was approved. Funds have been credited to your account.',
      'type': 'loan_approved',
      'isRead': 0,
      'createdAt': nowIso,
    });
  }

  Future<void> rejectLoanApplication({
    required String applicationId,
    required String userId,
    required String reason,
  }) async {
    final nowIso = DateTime.now().toIso8601String();

    await _db.updateLoanApplication(applicationId, {
      'status': 'Rejected',
      'rejectionReason': reason,
      'reviewedBy': 'local_admin',
      'reviewedAt': nowIso,
      'updatedAt': nowIso,
    });

    await _db.insertNotification({
      'id': 'notif_${DateTime.now().microsecondsSinceEpoch}',
      'userId': userId,
      'title': 'Loan Rejected',
      'message':
          'Your loan application ($applicationId) was rejected. Reason: $reason',
      'type': 'loan_rejected',
      'isRead': 0,
      'createdAt': nowIso,
    });
  }

  Future<List<AdminLoanApplicationModel>> getUserLoanApplicationsPaged(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final rows = await _db.getLoanApplicationsPaged(
      userId,
      limit: limit,
      offset: offset,
    );
    return rows
        .map(AdminLoanApplicationModel.fromSqlMap)
        .toList(growable: false);
  }

  Future<List<AdminTransactionModel>> getUserTransactionsPaged(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final rows = await _db.getTransactionsPaged(
      userId,
      limit: limit,
      offset: offset,
    );
    return rows.map(AdminTransactionModel.fromSqlMap).toList(growable: false);
  }

  Future<List<AdminNotificationModel>> getUserNotificationsPaged(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final rows = await _db.getNotificationsPaged(
      userId,
      limit: limit,
      offset: offset,
    );
    return rows.map(AdminNotificationModel.fromSqlMap).toList(growable: false);
  }

  Future<List<AdminLoanApplicationModel>> getAllLoanApplicationsForUser(
    String userId,
  ) async {
    final rows = await _db.getLoanApplications(userId);
    return rows
        .map(AdminLoanApplicationModel.fromSqlMap)
        .toList(growable: false);
  }

  Future<List<AdminTransactionModel>> getAllTransactionsForUser(
    String userId,
  ) async {
    final rows = await _db.getTransactions(userId, limit: 100000);
    return rows.map(AdminTransactionModel.fromSqlMap).toList(growable: false);
  }

  Future<List<AdminNotificationModel>> getAllNotificationsForUser(
    String userId,
  ) async {
    final rows = await _db.getNotifications(userId, limit: 100000);
    return rows.map(AdminNotificationModel.fromSqlMap).toList(growable: false);
  }

  int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  String _string(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  DateTime? _parseFlexibleDate(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty ||
        text == 'TBD' ||
        text == 'N/A' ||
        text == 'Awaiting approval') {
      return null;
    }

    final iso = DateTime.tryParse(text);
    if (iso != null) {
      return iso;
    }

    final parts = text.split('/');
    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }

    return DateTime(year, month, day);
  }
}
