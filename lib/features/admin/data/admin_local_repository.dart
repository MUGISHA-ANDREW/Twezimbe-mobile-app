import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<AdminUserModel>> watchUsersFromFirestore() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) {
                final data = doc.data();
                return AdminUserModel(
                  id: _string(data['uid']).isNotEmpty
                      ? _string(data['uid'])
                      : doc.id,
                  fullName: _string(data['name']).isNotEmpty
                      ? _string(data['name'])
                      : 'Unknown',
                  email: _string(data['email']),
                  phoneNumber: _string(data['phone']),
                  customerId: _string(data['customerId']),
                  kycStatus: _string(data['kycStatus']).isNotEmpty
                      ? _string(data['kycStatus'])
                      : 'Pending',
                  accountType: _string(data['accountType']).isNotEmpty
                      ? _string(data['accountType'])
                      : 'Savings Account',
                  photoUrl: _string(data['photoUrl']).isEmpty
                      ? null
                      : _string(data['photoUrl']),
                  isAdmin: _string(data['role']).toLowerCase() == 'admin',
                  balanceValue: _int(data['balanceValue']),
                  dateOfBirth: _string(data['dateOfBirth']),
                  nationalId: _string(data['nationalId']),
                  address: _string(data['address']),
                  createdAt: _toDateTime(data['createdAt']),
                  updatedAt: _toDateTime(data['updatedAt']),
                );
              })
              .toList(growable: false);
        });
  }

  Stream<List<AdminLoanApplicationModel>> watchLoanApplicationsFromFirestore() {
    return _firestore
        .collection('loan_applications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) {
                final data = doc.data();
                final status = _normalizeLoanStatus(_string(data['status']));
                return AdminLoanApplicationModel(
                  id: doc.id,
                  applicationId: _string(data['applicationId']).isNotEmpty
                      ? _string(data['applicationId'])
                      : doc.id,
                  userId: _string(data['userId']),
                  userName: _string(data['userName']),
                  userEmail: _string(data['userEmail']),
                  userPhone: _string(data['userPhone']),
                  customerId: _string(data['customerId']),
                  loanType: _string(data['loanType']),
                  amountValue: _int(data['amount'] ?? data['amountValue']),
                  period: _string(data['duration']).isNotEmpty
                      ? _string(data['duration'])
                      : _string(data['period']),
                  purpose: _string(data['purpose']),
                  status: status,
                  rejectionReason: _string(data['rejectionReason']).isEmpty
                      ? null
                      : _string(data['rejectionReason']),
                  reviewedBy: _string(data['adminId']).isEmpty
                      ? null
                      : _string(data['adminId']),
                  reviewedAt: _toDateTime(data['decisionAt']),
                  createdAt: _toDateTime(data['createdAt']),
                  updatedAt: _toDateTime(data['updatedAt']),
                );
              })
              .toList(growable: false);
        });
  }

  Stream<int> watchTotalUsersCountFromFirebase() {
    return _firestore.collection('users').snapshots().map((snap) => snap.size);
  }

  Stream<int> watchTotalIncomeFromFirebase() {
    return _firestore.collection('transactions').snapshots().map((snap) {
      var total = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final amount = _int(data['amountValue'] ?? data['amount']);
        final type = _string(data['type']).toLowerCase();
        final title = _string(data['title']).toLowerCase();
        final isIncome =
            type == 'deposit' ||
            type == 'repayment' ||
            title.contains('deposit') ||
            title.contains('repayment');
        if (isIncome && amount > 0) {
          total += amount;
        }
      }
      return total;
    });
  }

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
    // Keep local cache aligned with whichever Firebase user is currently signed in.
    await _syncCurrentSignedInUserToSqlite();

    // Pull full auth users list from a privileged backend callable, then cache in SQLite.
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'listAuthUsers',
      );
      final response = await callable.call();

      final data = response.data;
      if (data is! Map) {
        return;
      }

      final rawUsers = data['users'];
      if (rawUsers is! List) {
        return;
      }

      final rows = <Map<String, dynamic>>[];
      final nowIso = DateTime.now().toIso8601String();

      for (final entry in rawUsers) {
        if (entry is! Map) {
          continue;
        }

        final uid = _string(entry['uid']);
        if (uid.isEmpty) {
          continue;
        }

        final existing = await _db.getUser(uid);
        final email = _string(entry['email']);
        final fullName = _string(entry['displayName']).isNotEmpty
            ? _string(entry['displayName'])
            : _string(existing?['fullName']).isNotEmpty
            ? _string(existing?['fullName'])
            : (email.isNotEmpty ? email.split('@').first : 'Member');

        rows.add({
          'id': uid,
          'fullName': fullName,
          'email': email,
          'phoneNumber': _string(entry['phoneNumber']).isNotEmpty
              ? _string(entry['phoneNumber'])
              : _string(existing?['phoneNumber']),
          'dateOfBirth': _string(existing?['dateOfBirth']),
          'nationalId': _string(existing?['nationalId']),
          'address': _string(existing?['address']),
          'photoUrl': _string(entry['photoURL']).isNotEmpty
              ? _string(entry['photoURL'])
              : _string(existing?['photoUrl']),
          'customerId': _string(existing?['customerId']).isNotEmpty
              ? _string(existing?['customerId'])
              : _customerIdFromUid(uid),
          'kycStatus': _string(existing?['kycStatus']).isNotEmpty
              ? _string(existing?['kycStatus'])
              : 'Pending',
          'accountType': _string(existing?['accountType']).isNotEmpty
              ? _string(existing?['accountType'])
              : 'Savings Account',
          'balanceValue': _int(existing?['balanceValue']),
          'isAdmin': (_int(existing?['isAdmin']) == 1 || _isAdminEmail(email))
              ? 1
              : 0,
          'createdAt': _string(existing?['createdAt']).isNotEmpty
              ? _string(existing?['createdAt'])
              : (_string(entry['creationTime']).isNotEmpty
                    ? _string(entry['creationTime'])
                    : nowIso),
          'updatedAt': _string(entry['lastSignInTime']).isNotEmpty
              ? _string(entry['lastSignInTime'])
              : nowIso,
        });
      }

      if (rows.isNotEmpty) {
        await _db.upsertUsers(rows);
      }
    } on FirebaseFunctionsException {
      // Function unavailable/unauthorized: keep using local cache.
    } catch (_) {
      // Network/parse issue: keep using local cache.
    }
  }

  Future<void> _syncCurrentSignedInUserToSqlite() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      return;
    }

    final existing = await _db.getUser(current.uid);
    final nowIso = DateTime.now().toIso8601String();
    final email = _string(current.email).toLowerCase();
    final fullName = _string(current.displayName).isNotEmpty
        ? _string(current.displayName)
        : _string(existing?['fullName']).isNotEmpty
        ? _string(existing?['fullName'])
        : (email.isNotEmpty ? email.split('@').first : 'Member');

    final payload = <String, dynamic>{
      'id': current.uid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': _string(current.phoneNumber).isNotEmpty
          ? _string(current.phoneNumber)
          : _string(existing?['phoneNumber']),
      'dateOfBirth': _string(existing?['dateOfBirth']),
      'nationalId': _string(existing?['nationalId']),
      'address': _string(existing?['address']),
      'photoUrl': _string(current.photoURL).isNotEmpty
          ? _string(current.photoURL)
          : _string(existing?['photoUrl']),
      'customerId': _string(existing?['customerId']).isNotEmpty
          ? _string(existing?['customerId'])
          : _customerIdFromUid(current.uid),
      'kycStatus': _string(existing?['kycStatus']).isNotEmpty
          ? _string(existing?['kycStatus'])
          : 'Pending',
      'accountType': _string(existing?['accountType']).isNotEmpty
          ? _string(existing?['accountType'])
          : 'Savings Account',
      'balanceValue': _int(existing?['balanceValue']),
      'isAdmin': (_int(existing?['isAdmin']) == 1 || _isAdminEmail(email))
          ? 1
          : 0,
      'updatedAt': nowIso,
    };

    if (existing == null) {
      payload['createdAt'] =
          current.metadata.creationTime?.toIso8601String() ?? nowIso;
      await _db.insertUser(payload);
    } else {
      await _db.updateUser(current.uid, payload);
    }
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

    await _firestore.collection('users').doc(userId).set({
      'role': makeAdmin ? 'admin' : 'client',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteUser(String userId) async {
    await _db.deleteUserRelatedData(userId);

    await _firestore.collection('users').doc(userId).set({
      'deleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
    final totalRevenue = await _db.getTotalIncomeFromTransactions();
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
    final application = await _db.getLoanApplication(applicationId);
    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    if (application == null) {
      // ADD THIS: Firestore-first decision path when admin device has no local row.
      await _firestore.collection('loan_applications').doc(applicationId).set({
        'status': 'approved',
        'decisionAt': FieldValue.serverTimestamp(),
        'adminId': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final approvedNotifRef = _firestore.collection('notifications').doc();
      await approvedNotifRef.set({
        'id': approvedNotifRef.id,
        'userId': userId,
        'title': 'Loan Approved',
        'message':
            'Your loan application ($applicationId) was approved. Funds have been credited to your account.',
        'type': 'loan',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final currentStatus = _string(application['status']);
    if (currentStatus != 'Pending Review') {
      throw StateError('Only pending applications can be approved.');
    }

    final effectiveApplicationId =
        _string(application['applicationId']).isNotEmpty
        ? _string(application['applicationId'])
        : _string(application['id']);
    if (effectiveApplicationId.isEmpty) {
      throw StateError('Loan application has no valid identifier.');
    }

    await _db.updateLoanApplication(effectiveApplicationId, {
      'status': 'Approved',
      'rejectionReason': null,
      'reviewedBy': 'local_admin',
      'reviewedAt': nowIso,
      'updatedAt': nowIso,
    });

    final latestLoan = await _db.getLatestLoanForUser(userId);
    if (latestLoan == null) {
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
      final latestStatus = _string(latestLoan['status']);
      if (latestStatus == 'Active' || latestStatus == 'Approved') {
        final currentRemaining = _int(latestLoan['remainingBalanceValue']);
        final currentPrincipal = _int(latestLoan['amountValue']);
        await _db.updateLoan(latestLoan['id'].toString(), {
          'remainingBalanceValue': currentRemaining + amountValue,
          'amountValue': currentPrincipal + amountValue,
          'updatedAt': nowIso,
        });
      } else {
        await _db.updateLoan(latestLoan['id'].toString(), {
          'loanId': _string(latestLoan['loanId']).isNotEmpty
              ? _string(latestLoan['loanId'])
              : 'LN${now.millisecondsSinceEpoch}',
          'type': loanType,
          'status': 'Active',
          'amountValue': amountValue,
          'remainingBalanceValue': amountValue,
          'period': period,
          'purpose': purpose,
          'nextPaymentDate': now
              .add(const Duration(days: 30))
              .toIso8601String(),
          'repaymentProgress': 0,
          'updatedAt': nowIso,
        });
      }
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
          'Your loan application ($effectiveApplicationId) was approved. Funds have been credited to your account.',
      'type': 'loan_approved',
      'isRead': 0,
      'createdAt': nowIso,
    });

    // ADD THIS: keep Firestore admin loan workflow updated.
    await _firestore
        .collection('loan_applications')
        .doc(effectiveApplicationId)
        .set({
          'status': 'approved',
          'decisionAt': FieldValue.serverTimestamp(),
          'adminId': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    final approvedNotifRef = _firestore.collection('notifications').doc();
    await approvedNotifRef.set({
      'id': approvedNotifRef.id,
      'userId': userId,
      'title': 'Loan Approved',
      'message':
          'Your loan application ($effectiveApplicationId) was approved. Funds have been credited to your account.',
      'type': 'loan',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectLoanApplication({
    required String applicationId,
    required String userId,
    required String reason,
  }) async {
    final application = await _db.getLoanApplication(applicationId);
    final cleanReason = reason.trim().isEmpty
        ? 'Please contact support for guidance.'
        : reason.trim();
    final nowIso = DateTime.now().toIso8601String();

    if (application == null) {
      // ADD THIS: Firestore-first decision path when admin device has no local row.
      await _firestore.collection('loan_applications').doc(applicationId).set({
        'status': 'rejected',
        'rejectionReason': cleanReason,
        'decisionAt': FieldValue.serverTimestamp(),
        'adminId': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final rejectedNotifRef = _firestore.collection('notifications').doc();
      await rejectedNotifRef.set({
        'id': rejectedNotifRef.id,
        'userId': userId,
        'title': 'Loan Rejected',
        'message':
            'Your loan application ($applicationId) was rejected. Reason: $cleanReason',
        'type': 'loan',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final currentStatus = _string(application['status']);
    if (currentStatus != 'Pending Review') {
      throw StateError('Only pending applications can be rejected.');
    }

    final effectiveApplicationId =
        _string(application['applicationId']).isNotEmpty
        ? _string(application['applicationId'])
        : _string(application['id']);
    if (effectiveApplicationId.isEmpty) {
      throw StateError('Loan application has no valid identifier.');
    }

    await _db.updateLoanApplication(effectiveApplicationId, {
      'status': 'Rejected',
      'rejectionReason': cleanReason,
      'reviewedBy': 'local_admin',
      'reviewedAt': nowIso,
      'updatedAt': nowIso,
    });

    final latestLoan = await _db.getLatestLoanForUser(userId);
    if (latestLoan != null &&
        _string(latestLoan['status']) == 'Pending Review') {
      await _db.updateLoan(latestLoan['id'].toString(), {
        'status': 'Rejected',
        'nextPaymentDate': 'Awaiting new application',
        'repaymentProgress': 0,
        'updatedAt': nowIso,
      });
    }

    await _db.insertNotification({
      'id': 'notif_${DateTime.now().microsecondsSinceEpoch}',
      'userId': userId,
      'title': 'Loan Rejected',
      'message':
          'Your loan application ($effectiveApplicationId) was rejected. Reason: $cleanReason',
      'type': 'loan_rejected',
      'isRead': 0,
      'createdAt': nowIso,
    });

    // ADD THIS: keep Firestore admin loan workflow updated.
    await _firestore
        .collection('loan_applications')
        .doc(effectiveApplicationId)
        .set({
          'status': 'rejected',
          'rejectionReason': cleanReason,
          'decisionAt': FieldValue.serverTimestamp(),
          'adminId': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    final rejectedNotifRef = _firestore.collection('notifications').doc();
    await rejectedNotifRef.set({
      'id': rejectedNotifRef.id,
      'userId': userId,
      'title': 'Loan Rejected',
      'message':
          'Your loan application ($effectiveApplicationId) was rejected. Reason: $cleanReason',
      'type': 'loan',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
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

  String _customerIdFromUid(String uid) {
    final normalized = uid.codeUnits.fold<int>(
      0,
      (accumulator, code) => (accumulator + code) % 99999,
    );
    final suffix = normalized.toString().padLeft(5, '0');
    return 'CUS$suffix';
  }

  bool _isAdminEmail(String email) {
    return email.trim().toLowerCase() == 'admin@twezimbe.co.ug';
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

  DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String _normalizeLoanStatus(String raw) {
    final value = raw.toLowerCase();
    if (value == 'approved') return 'Approved';
    if (value == 'rejected') return 'Rejected';
    if (value == 'pending') return 'Pending';
    if (raw.trim().isEmpty) return 'Pending';
    return raw;
  }
}
