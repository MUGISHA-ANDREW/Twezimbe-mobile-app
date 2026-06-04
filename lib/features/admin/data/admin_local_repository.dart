import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twezimbeapp/core/data/change_bus.dart';
import 'package:twezimbeapp/core/data/db_constants.dart';
import 'package:twezimbeapp/features/admin/domain/models/admin_loan_application_model.dart';
import 'package:twezimbeapp/features/admin/domain/models/admin_notification_model.dart';
import 'package:twezimbeapp/features/admin/domain/models/admin_transaction_model.dart';
import 'package:twezimbeapp/features/admin/domain/models/admin_user_model.dart';



void debugStep(String step) {
  print('🟡 [ADMIN FLOW] $step');
}

void debugSuccess(String step) {
  print('🟢 [ADMIN FLOW] $step');
}

void debugError(String step, Object e) {
  print('🔴 [ADMIN FLOW ERROR] $step');
  print('   └── $e');
}
/// Supabase-backed admin repository.
class AdminLocalRepository {
  AdminLocalRepository._();

  static final AdminLocalRepository _instance = AdminLocalRepository._();
  factory AdminLocalRepository() => _instance;

  static const String _usersStatusFilterKey =
      'admin_users_status_filter_preference';
  static const String _loanStatusFilterKey =
      'admin_loans_status_filter_preference';

  static SupabaseClient get _sb => Supabase.instance.client;
  final DatabaseChangeBus _bus = DatabaseChangeBus.instance;

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  Stream<List<AdminUserModel>> watchUsers() {
    final controller =
        StreamController<List<AdminUserModel>>.broadcast();
    StreamSubscription<String>? sub;

    Future<void> emit() async {
      try {
        final rows = await _sb
            .from('users')
            .select()
            .order('created_at', ascending: false);
        controller.add(
          rows.map(AdminUserModel.fromSqlMap).toList(),
        );
      } catch (_) {
        controller.add([]);
      }
    }

    controller.onListen = () {
      unawaited(emit());
      sub = _bus.stream.where((t) => t == DbTables.users).listen((_) {
        unawaited(emit());
      });
    };

    controller.onCancel = () async => sub?.cancel();

    return controller.stream;
  }

  Stream<List<AdminLoanApplicationModel>> watchLoanApplications() {
    final controller =
        StreamController<List<AdminLoanApplicationModel>>.broadcast();
    StreamSubscription<String>? sub;

    Future<void> emit() async {
      try {
        final rows = await _sb
            .from('loan_applications')
            .select()
            .order('created_at', ascending: false);
        controller.add(
          rows
              .map(AdminLoanApplicationModel.fromSqlMap)
              .toList(growable: false),
        );
      } catch (_) {
        controller.add([]);
      }
    }

    controller.onListen = () {
      unawaited(emit());
      sub = _bus.stream
          .where((t) => t == DbTables.loanApplications)
          .listen((_) => unawaited(emit()));
    };

    controller.onCancel = () async => sub?.cancel();

    return controller.stream;
  }

  Stream<int> watchTotalUsersCount() {
    final controller = StreamController<int>.broadcast();
    StreamSubscription<String>? sub;

    Future<void> emit() async {
      try {
        final rows = await _sb.from('users').select('id');
        controller.add(rows.length);
      } catch (_) {
        controller.add(0);
      }
    }

    controller.onListen = () {
      unawaited(emit());
      sub = _bus.stream.where((t) => t == DbTables.users).listen((_) {
        unawaited(emit());
      });
    };

    controller.onCancel = () async => sub?.cancel();

    return controller.stream;
  }

  Stream<int> watchTotalIncome() {
    final controller = StreamController<int>.broadcast();
    StreamSubscription<String>? sub;

    Future<void> emit() async {
      try {
        final rows = await _sb
            .from('transactions')
            .select('amount_value, is_credit, title');
        int total = 0;
        for (final row in rows) {
          final isCredit = row['is_credit'] == true;
          final title = (row['title'] ?? '').toString().toLowerCase();
          if (isCredit || title.contains('repayment')) {
            total += (row['amount_value'] as num?)?.toInt() ?? 0;
          }
        }
        controller.add(total);
      } catch (_) {
        controller.add(0);
      }
    }

    controller.onListen = () {
      unawaited(emit());
      sub = _bus.stream
          .where((t) => t == DbTables.transactions)
          .listen((_) => unawaited(emit()));
    };

    controller.onCancel = () async => sub?.cancel();

    return controller.stream;
  }

  // ---------------------------------------------------------------------------
  // Filter preferences
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Sync helpers (no-ops — Supabase IS the remote)
  // ---------------------------------------------------------------------------

  Future<void> syncUsersFromRemote() async {
    _bus.notify(DbTables.users);
  }

  Future<void> syncLoanApplicationsFromRemote() async {
    _bus.notify(DbTables.loanApplications);
  }

  Future<void> syncUserCollectionsFromRemote(String userId) async {
    _bus.notify(DbTables.transactions);
    _bus.notify(DbTables.notifications);
  }

  // ---------------------------------------------------------------------------
  // User queries
  // ---------------------------------------------------------------------------

  Future<List<AdminUserModel>> getUsers({
    String searchQuery = '',
    String statusFilter = 'All',
  }) async {
    try {
      final rows = await _sb
          .from('users')
          .select()
          .order('created_at', ascending: false);
      var users =
          rows.map(AdminUserModel.fromSqlMap).toList(growable: false);

      final normalizedQuery = searchQuery.trim().toLowerCase();
      if (normalizedQuery.isNotEmpty) {
        users = users.where((u) {
          return u.fullName.toLowerCase().contains(normalizedQuery) ||
              u.email.toLowerCase().contains(normalizedQuery);
        }).toList(growable: false);
      }

      users = users.where((u) {
        if (statusFilter == 'All') return true;
        if (statusFilter == 'KYC Verified') return u.kycStatus == 'KYC Verified';
        if (statusFilter == 'Rejected') return u.kycStatus == 'Rejected';
        if (statusFilter == 'Pending') {
          return u.kycStatus != 'KYC Verified' &&
              u.kycStatus != 'Rejected';
        }
        return true;
      }).toList(growable: false);

      return users;
    } catch (_) {
      return [];
    }
  }

  Future<void> updateKycStatus(String userId, String status) async {
    try {
      await _sb.from('users').update({
        'kyc_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      _bus.notify(DbTables.users);
    } catch (_) {}
  }

  Future<void> toggleAdminRole(String userId, bool makeAdmin) async {
    try {
      await _sb.from('users').update({
        'is_admin': makeAdmin,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      _bus.notify(DbTables.users);
    } catch (_) {}
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Delete related data first (RLS permitting)
      await _sb.from('notifications').delete().eq('user_id', userId);
      await _sb.from('transactions').delete().eq('user_id', userId);
      await _sb.from('loan_applications').delete().eq('user_id', userId);
      await _sb.from('loans').delete().eq('user_id', userId);
      await _sb.from('users').delete().eq('id', userId);
      _bus.notify(DbTables.users);
    } catch (_) {}
  }

  Future<List<AdminLoanApplicationModel>> getLoanApplications({
    String statusFilter = 'All',
  }) async {
    try {
      var query = _sb
          .from('loan_applications')
          .select()
          .order('created_at', ascending: false);

      final rows = await query;
      var apps = rows
          .map(AdminLoanApplicationModel.fromSqlMap)
          .toList(growable: false);

      if (statusFilter != 'All') {
        apps = apps
            .where((app) => app.status == statusFilter)
            .toList(growable: false);
      }

      return apps;
    } catch (_) {
      return [];
    }
  }

  Future<AdminUserModel?> getUserById(String userId) async {
    try {
      final row = await _sb
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return null;
      return AdminUserModel.fromSqlMap(row);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, int>> getDashboardMetrics() async {
    final totalUsers = await _getTotalUsersCount();
    final activeLoans = await _getActiveLoansCount();
    final defaulters = await getDefaultersCount();
    final totalRevenue = await _getTotalIncomeFromTransactions();
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
    try {
      final rows = await _sb.from('loans').select();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final defaulterIds = <String>{};

      for (final row in rows) {
        final status = _str(row['status']).toLowerCase();
        if (status != DbStatus.active.toLowerCase() &&
            status != DbStatus.approved.toLowerCase()) {
          continue;
        }

        final remaining = _int(row['remaining_balance_value']);
        if (remaining <= 0) continue;

        final dueDate = _parseFlexibleDate(_str(row['next_payment_date']));
        if (dueDate == null) continue;

        final normalizedDue =
            DateTime(dueDate.year, dueDate.month, dueDate.day);
        if (normalizedDue.isBefore(today)) {
          final userId = _str(row['user_id']);
          if (userId.isNotEmpty) defaulterIds.add(userId);
        }
      }

      return defaulterIds;
    } catch (_) {
      return {};
    }
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

    List<String> allUserIds = [];
    try {
      final rows = await _sb.from('users').select('id');
      allUserIds = rows.map((r) => _str(r['id'])).where((id) => id.isNotEmpty).toList();
    } catch (_) {}

    List<String> recipients;
    if (audience == 'specific') {
      final selected = (userId ?? '').trim();
      if (selected.isEmpty) throw ArgumentError('Please select a recipient.');
      if (!allUserIds.contains(selected)) {
        throw StateError('Selected recipient does not exist.');
      }
      recipients = [selected];
    } else if (audience == 'defaulters') {
      recipients = (await getDefaulterUserIds()).toList();
    } else {
      recipients = allUserIds;
    }

    if (recipients.isEmpty) return 0;

    final nowIso = DateTime.now().toIso8601String();
    for (int i = 0; i < recipients.length; i++) {
      try {
        await _sb.from('notifications').insert({
          'user_id': recipients[i],
          'title': cleanTitle,
          'message': cleanMessage,
          'type': 'admin_update',
          'is_read': false,
          'created_at': nowIso,
          'updated_at': nowIso,
          'sync_status': DbSyncStatus.synced,
          'version': 0,
        });
      } catch (_) {}
    }

    _bus.notify(DbTables.notifications);
    return recipients.length;
  }

  Future<List<AdminUserModel>> getRecentUsers({int limit = 5}) async {
    try {
      final rows = await _sb
          .from('users')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map(AdminUserModel.fromSqlMap).toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Loan approval / rejection
  // ---------------------------------------------------------------------------

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

  print('🟡 START approveLoanApplication');
  print('➡️ applicationId: $applicationId');
  print('➡️ userId: $userId');
  print('➡️ amountValue: $amountValue');
  print('➡️ loanType: $loanType');

  // =========================================================
  // 🔍 SAFE APPLICATION LOOKUP (FIXED UUID CRASH HERE)
  // =========================================================
  List<Map<String, dynamic>> appRows = [];

  try {
    print('🔍 fetching loan_application by application_id...');

    // 1️⃣ try application_id (TEXT)
    appRows = await _sb
        .from('loan_applications')
        .select()
        .eq('application_id', applicationId)
        .limit(1);

    print('📌 step 1 result (application_id): $appRows');

    // 2️⃣ fallback to UUID id ONLY if needed
    if (appRows.isEmpty) {
      print('🔁 fallback: trying UUID id match...');

      appRows = await _sb
          .from('loan_applications')
          .select()
          .eq('id', applicationId) // SAFE: only UUID column here
          .limit(1);

      print('📌 step 2 result (id): $appRows');
    }
  } catch (e, st) {
    print('❌ ERROR fetching loan application: $e');
    print(st);
  }

  if (appRows.isEmpty) {
    print('❌ Loan application NOT FOUND');
    throw StateError('Loan application not found.');
  }

  final application = appRows.first;
  final currentStatus = _str(application['status']);

  print('📌 currentStatus: $currentStatus');

  if (currentStatus != DbStatus.pending &&
      currentStatus != 'Pending Review') {
    print('❌ Invalid status for approval: $currentStatus');
    throw StateError('Only pending applications can be approved.');
  }

  final effectiveAppId = _str(
    application['application_id'] ?? application['id'],
  );

  print('📌 effectiveAppId: $effectiveAppId');

  if (effectiveAppId.isEmpty) {
    throw StateError('Loan application has no valid identifier.');
  }

  // =========================================================
  // ✏️ UPDATE APPLICATION
  // =========================================================
  try {
    print('✏️ updating loan_application status...');

    final res = await _sb.from('loan_applications').update({
      'status': DbStatus.approved,
      'rejection_reason': null,
      'reviewed_by': 'admin',
      'reviewed_at': nowIso,
      'updated_at': nowIso,
    }).eq('application_id', application['application_id']);

    print('✅ loan_applications update response: $res');
  } catch (e, st) {
    print('❌ ERROR updating loan application: $e');
    print(st);
  }

  // =========================================================
  // 🏦 LOAN FETCH
  // =========================================================
  List<Map<String, dynamic>> loanRows = [];

  try {
    print('🔍 fetching loans for user...');

    loanRows = await _sb
        .from('loans')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1);

    print('📌 loan fetch result: $loanRows');
  } catch (e, st) {
    print('❌ ERROR fetching loans: $e');
    print(st);
  }

  try {
    if (loanRows.isEmpty) {
      print('➕ creating new loan...');

      final insertRes = await _sb.from('loans').insert({
        'user_id': userId,
        'loan_id': 'LN${now.millisecondsSinceEpoch}',
        'loan_type': loanType,
        'status': DbStatus.active,
        'amount_value': amountValue,
        'remaining_balance_value': amountValue,
        'period': period,
        'purpose': purpose,
        'next_payment_date':
            now.add(const Duration(days: 30)).toIso8601String(),
        'repayment_progress': 0,
        'created_at': nowIso,
        'updated_at': nowIso,
        'sync_status': DbSyncStatus.synced,
        'version': 0,
      });

      print('✅ loan insert response: $insertRes');
    } else {
      final existingLoan = loanRows.first;
      final existingStatus = _str(existingLoan['status']);

      print('📌 existing loan status: $existingStatus');

      if (existingStatus == DbStatus.active ||
          existingStatus == DbStatus.approved) {
        final currentRemaining =
            _int(existingLoan['remaining_balance_value']);
        final currentPrincipal =
            _int(existingLoan['amount_value']);

        print('🔄 updating existing active loan...');

        final updateRes = await _sb.from('loans').update({
          'remaining_balance_value': currentRemaining + amountValue,
          'amount_value': currentPrincipal + amountValue,
          'updated_at': nowIso,
        }).eq('id', existingLoan['id']);

        print('✅ loan update response: $updateRes');
      } else {
        print('🔄 reactivating loan...');

        final updateRes = await _sb.from('loans').update({
          'loan_id': _str(existingLoan['loan_id']).isNotEmpty
              ? _str(existingLoan['loan_id'])
              : 'LN${now.millisecondsSinceEpoch}',
          'loan_type': loanType,
          'status': DbStatus.active,
          'amount_value': amountValue,
          'remaining_balance_value': amountValue,
          'period': period,
          'purpose': purpose,
          'next_payment_date':
              now.add(const Duration(days: 30)).toIso8601String(),
          'repayment_progress': 0,
          'updated_at': nowIso,
        }).eq('id', existingLoan['id']);

        print('✅ loan reactivation response: $updateRes');
      }
    }
  } catch (e, st) {
    print('❌ ERROR handling loan creation/update: $e');
    print(st);
  }

  // =========================================================
  // 💰 USER BALANCE UPDATE
  // =========================================================
  try {
    print('💰 fetching user balance...');

    final userRow = await _sb
        .from('users')
        .select('balance_value')
        .eq('id', userId)
        .maybeSingle();

    print('👤 user row: $userRow');

    final currentBalance = _int(userRow?['balance_value']);

    final updateRes = await _sb.from('users').update({
      'balance_value': currentBalance + amountValue,
      'updated_at': nowIso,
    }).eq('id', userId);

    print('✅ user balance update: $updateRes');
  } catch (e, st) {
    print('❌ ERROR updating user balance: $e');
    print(st);
  }

  // =========================================================
  // 💳 TRANSACTION
  // =========================================================
  try {
    print('💳 inserting transaction...');

    final txRes = await _sb.from('transactions').insert({
      'user_id': userId,
      'title': 'Loan Approved',
      'subtitle': '$loanType approved and credited',
      'amount_value': amountValue,
      'is_credit': true,
      'created_at': nowIso,
      'updated_at': nowIso,
      'sync_status': DbSyncStatus.synced,
      'version': 0,
    });

    print('✅ transaction insert: $txRes');
  } catch (e, st) {
    print('❌ ERROR inserting transaction: $e');
    print(st);
  }

  // =========================================================
  // 🔔 NOTIFICATION
  // =========================================================
  try {
    print('🔔 inserting notification...');

    final noteRes = await _sb.from('notifications').insert({
      'user_id': userId,
      'title': 'Loan Approved',
      'message':
          'Your loan application ($effectiveAppId) was approved. Funds have been credited to your account.',
      'type': 'loan_approved',
      'is_read': false,
      'created_at': nowIso,
      'updated_at': nowIso,
      'sync_status': DbSyncStatus.synced,
      'version': 0,
    });

    print('✅ notification insert: $noteRes');
  } catch (e, st) {
    print('❌ ERROR inserting notification: $e');
    print(st);
  }

  print('🏁 FINISHED approveLoanApplication');

  _bus.notify(DbTables.loanApplications);
  _bus.notify(DbTables.loans);
  _bus.notify(DbTables.transactions);
  _bus.notify(DbTables.notifications);
  _bus.notify(DbTables.users);
}

  Future<void> rejectLoanApplication({
    required String applicationId,
    required String userId,
    required String reason,
  }) async {
    final cleanReason = reason.trim().isEmpty
        ? 'Please contact support for guidance.'
        : reason.trim();
    final nowIso = DateTime.now().toIso8601String();

    List<Map<String, dynamic>> appRows = [];
    try {
      appRows = await _sb
          .from('loan_applications')
          .select()
          .or('application_id.eq.$applicationId,id.eq.$applicationId')
          .limit(1);
    } catch (_) {}

    if (appRows.isEmpty) throw StateError('Loan application not found.');

    final currentStatus = _str(appRows.first['status']);
    if (currentStatus != DbStatus.pending &&
        currentStatus != 'Pending Review') {
      throw StateError('Only pending applications can be rejected.');
    }

    final effectiveAppId = _str(
      appRows.first['application_id'] ?? appRows.first['id'],
    );

    try {
      await _sb.from('loan_applications').update({
        'status': DbStatus.rejected,
        'rejection_reason': cleanReason,
        'reviewed_by': 'admin',
        'reviewed_at': nowIso,
        'updated_at': nowIso,
      }).or('application_id.eq.$effectiveAppId,id.eq.$effectiveAppId');
    } catch (_) {}

    // Update loan status if pending
    try {
      final loanRows = await _sb
          .from('loans')
          .select('id, status')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1);
      if (loanRows.isNotEmpty) {
        final loanStatus = _str(loanRows.first['status']);
        if (loanStatus == DbStatus.pending ||
            loanStatus == 'Pending Review') {
          await _sb.from('loans').update({
            'status': DbStatus.rejected,
            'next_payment_date': 'Awaiting new application',
            'repayment_progress': 0,
            'updated_at': nowIso,
          }).eq('id', loanRows.first['id']);
        }
      }
    } catch (_) {}

    try {
      await _sb.from('notifications').insert({
        'user_id': userId,
        'title': 'Loan Rejected',
        'message':
            'Your loan application ($effectiveAppId) was rejected. Reason: $cleanReason',
        'type': 'loan_rejected',
        'is_read': false,
        'created_at': nowIso,
        'updated_at': nowIso,
        'sync_status': DbSyncStatus.synced,
        'version': 0,
      });
    } catch (_) {}

    _bus.notify(DbTables.loanApplications);
    _bus.notify(DbTables.loans);
    _bus.notify(DbTables.notifications);
  }

  // ---------------------------------------------------------------------------
  // Paged queries for user detail
  // ---------------------------------------------------------------------------

  Future<List<AdminLoanApplicationModel>> getUserLoanApplicationsPaged(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final rows = await _sb
          .from('loan_applications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return rows
          .map(AdminLoanApplicationModel.fromSqlMap)
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  Future<List<AdminTransactionModel>> getUserTransactionsPaged(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final rows = await _sb
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return rows
          .map(AdminTransactionModel.fromSqlMap)
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  Future<List<AdminNotificationModel>> getUserNotificationsPaged(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final rows = await _sb
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return rows
          .map(AdminNotificationModel.fromSqlMap)
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  Future<List<AdminLoanApplicationModel>> getAllLoanApplicationsForUser(
    String userId,
  ) async {
    try {
      final rows = await _sb
          .from('loan_applications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return rows
          .map(AdminLoanApplicationModel.fromSqlMap)
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  Future<List<AdminTransactionModel>> getAllTransactionsForUser(
    String userId,
  ) async {
    try {
      final rows = await _sb
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return rows
          .map(AdminTransactionModel.fromSqlMap)
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  Future<List<AdminNotificationModel>> getAllNotificationsForUser(
    String userId,
  ) async {
    try {
      final rows = await _sb
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return rows
          .map(AdminNotificationModel.fromSqlMap)
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Direct loan creation (no application required)
  // ---------------------------------------------------------------------------

  Future<void> createLoanForUser({
    required String userId,
    required int amountValue,
    required String loanType,
    required String period,
    required String purpose,
  }) async {
    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    try {
      await _sb.from('loans').insert({
        'user_id': userId,
        'loan_id': 'LN${now.millisecondsSinceEpoch}',
        'loan_type': loanType,
        'status': DbStatus.active,
        'amount_value': amountValue,
        'remaining_balance_value': amountValue,
        'period': period,
        'purpose': purpose,
        'next_payment_date': now.add(const Duration(days: 30)).toIso8601String(),
        'repayment_progress': 0,
        'created_at': nowIso,
        'updated_at': nowIso,
        'sync_status': DbSyncStatus.synced,
        'version': 0,
      });
    } catch (_) {}

    try {
      final userRow = await _sb
          .from('users')
          .select('balance_value')
          .eq('id', userId)
          .maybeSingle();
      final current = _int(userRow?['balance_value']);
      await _sb.from('users').update({
        'balance_value': current + amountValue,
        'updated_at': nowIso,
      }).eq('id', userId);
    } catch (_) {}

    try {
      await _sb.from('transactions').insert({
        'user_id': userId,
        'title': 'Loan Disbursed',
        'subtitle': '$loanType issued by admin',
        'amount_value': amountValue,
        'is_credit': true,
        'created_at': nowIso,
        'updated_at': nowIso,
        'sync_status': DbSyncStatus.synced,
        'version': 0,
      });
    } catch (_) {}

    try {
      await _sb.from('notifications').insert({
        'user_id': userId,
        'title': 'Loan Issued',
        'message':
            'A $loanType loan of UGX ${_formatAmount(amountValue)} has been credited to your account.',
        'type': 'loan_approved',
        'is_read': false,
        'created_at': nowIso,
        'updated_at': nowIso,
        'sync_status': DbSyncStatus.synced,
        'version': 0,
      });
    } catch (_) {}

    _bus.notify(DbTables.loans);
    _bus.notify(DbTables.transactions);
    _bus.notify(DbTables.notifications);
    _bus.notify(DbTables.users);
  }

  // ---------------------------------------------------------------------------
  // Active loans
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getAllActiveLoans() async {
    try {
      return await _sb
          .from('loans')
          .select()
          .order('created_at', ascending: false);
    } catch (_) {
      return [];
    }
  }

  Future<void> markLoanAsPaidOff(String loanId) async {
    final nowIso = DateTime.now().toIso8601String();
    try {
      await _sb.from('loans').update({
        'status': 'Paid Off',
        'remaining_balance_value': 0,
        'repayment_progress': 100,
        'updated_at': nowIso,
      }).eq('id', loanId);
      _bus.notify(DbTables.loans);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // All transactions (admin view)
  // ---------------------------------------------------------------------------

  Future<List<AdminTransactionModel>> getAllTransactions({
    int limit = 200,
  }) async {
    try {
      final rows = await _sb
          .from('transactions')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map(AdminTransactionModel.fromSqlMap).toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Loan products CRUD
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getLoanProducts() async {
    try {
      return await _sb
          .from('loan_products')
          .select()
          .order('created_at', ascending: false);
    } catch (_) {
      return [];
    }
  }

  Future<void> createLoanProduct({
    required String name,
    required int maxAmountValue,
    required int interestRateBps,
    required String periods,
    bool isActive = true,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    try {
      await _sb.from('loan_products').insert({
        'name': name,
        'max_amount_value': maxAmountValue,
        'interest_rate_bps': interestRateBps,
        'periods': periods,
        'is_active': isActive,
        'created_at': nowIso,
        'updated_at': nowIso,
      });
    } catch (_) {}
  }

  Future<void> updateLoanProduct(
    String id, {
    String? name,
    int? maxAmountValue,
    int? interestRateBps,
    String? periods,
    bool? isActive,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final updates = <String, dynamic>{'updated_at': nowIso};
    if (name != null) updates['name'] = name;
    if (maxAmountValue != null) updates['max_amount_value'] = maxAmountValue;
    if (interestRateBps != null) updates['interest_rate_bps'] = interestRateBps;
    if (periods != null) updates['periods'] = periods;
    if (isActive != null) updates['is_active'] = isActive;
    try {
      await _sb.from('loan_products').update(updates).eq('id', id);
    } catch (_) {}
  }

  Future<void> deleteLoanProduct(String id) async {
    try {
      await _sb.from('loan_products').delete().eq('id', id);
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Report data
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getReportData() async {
    int totalDeposits = 0;
    int totalWithdrawals = 0;
    int totalLoansIssued = 0;
    int totalRepayments = 0;
    int outstandingBalance = 0;

    try {
      final txRows = await _sb.from('transactions').select(
            'amount_value, is_credit, title',
          );
      for (final row in txRows) {
        final amt = _int(row['amount_value']);
        final isCredit = row['is_credit'] == true;
        final title = _str(row['title']).toLowerCase();
        if (isCredit && title.contains('deposit')) totalDeposits += amt;
        if (!isCredit && title.contains('withdrawal')) totalWithdrawals += amt;
        if (isCredit && (title.contains('loan') || title.contains('disburs'))) {
          totalLoansIssued += amt;
        }
        if (!isCredit && title.contains('repayment')) totalRepayments += amt;
      }
    } catch (_) {}

    try {
      final loanRows = await _sb
          .from('loans')
          .select('remaining_balance_value, status');
      for (final row in loanRows) {
        final status = _str(row['status']).toLowerCase();
        if (status == 'active' || status == 'approved') {
          outstandingBalance += _int(row['remaining_balance_value']);
        }
      }
    } catch (_) {}

    return {
      'totalDeposits': totalDeposits,
      'totalWithdrawals': totalWithdrawals,
      'totalLoansIssued': totalLoansIssued,
      'totalRepayments': totalRepayments,
      'outstandingBalance': outstandingBalance,
    };
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  String _formatAmount(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final idxFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }

  Future<int> _getTotalUsersCount() async {
    try {
      final rows = await _sb.from('users').select('id');
      return rows.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _getActiveLoansCount() async {
    try {
      final rows = await _sb
          .from('loan_applications')
          .select('id')
          .or('status.eq.${DbStatus.approved},status.eq.${DbStatus.active}');
      return rows.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _getTotalIncomeFromTransactions() async {
    try {
      final rows = await _sb
          .from('transactions')
          .select('amount_value, is_credit, title');
      int total = 0;
      for (final row in rows) {
        final isCredit = row['is_credit'] == true;
        final title = (row['title'] ?? '').toString().toLowerCase();
        if (isCredit || title.contains('repayment')) {
          total += _int(row['amount_value']);
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  int _int(dynamic value) {
    if (value is bool) return value ? 1 : 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  String _str(dynamic value) {
    if (value == null) return '';
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
    if (iso != null) return iso;
    final parts = text.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }
}
