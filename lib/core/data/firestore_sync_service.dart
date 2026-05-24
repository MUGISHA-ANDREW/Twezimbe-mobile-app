import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:twezimbeapp/core/constants/app_timeouts.dart';

class FirestoreSyncService {
  FirestoreSyncService._();

  static final FirestoreSyncService instance = FirestoreSyncService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<T> _runWithTimeout<T>(Future<T> operation) {
    return operation.timeout(kAppOperationTimeout);
  }

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _loanApplications =>
      _firestore.collection('loan_applications');
  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');
  CollectionReference<Map<String, dynamic>> get _transactions =>
      _firestore.collection('transactions');
  CollectionReference<Map<String, dynamic>> get _loans =>
      _firestore.collection('loans');

  // ADD THIS: sync auth user profile into Firestore users collection.
  Future<void> ensureUserDocument({
    required User user,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? fcmToken,
  }) async {
    final docRef = _users.doc(user.uid);
    final snapshot = await _runWithTimeout(docRef.get());

    final resolvedRole = (role == null || role.trim().isEmpty)
        ? 'client'
        : role.trim().toLowerCase();

    final payload = <String, dynamic>{
      'uid': user.uid,
      'fullName': _clean(name) ?? _clean(user.displayName) ?? '',
      'email': (_clean(email) ?? _clean(user.email) ?? '').toLowerCase(),
      'phoneNumber': _clean(phone) ?? _clean(user.phoneNumber) ?? '',
      'role': resolvedRole,
      'fcmToken': _clean(fcmToken) ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (user.photoURL != null) {
      payload['photoUrl'] = user.photoURL;
    }

    if (!snapshot.exists) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      payload['balanceValue'] = 0;
      await _runWithTimeout(docRef.set(payload));
      return;
    }

    await _runWithTimeout(docRef.set(payload, SetOptions(merge: true)));
  }

  // ADD THIS: update FCM token in users collection.
  Future<void> updateFcmToken({
    required String uid,
    required String token,
  }) async {
    if (uid.trim().isEmpty || token.trim().isEmpty) return;

    await _runWithTimeout(
      _users.doc(uid).set({
        'uid': uid,
        'fcmToken': token.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }

  // ADD THIS: realtime users stream for admin screen.
  Stream<List<Map<String, dynamic>>> streamUsers() {
    return _users.orderBy('createdAt', descending: true).snapshots().map((
      snap,
    ) {
      return snap.docs
          .map((doc) {
            final data = doc.data();
            return <String, dynamic>{'id': doc.id, ...data};
          })
          .toList(growable: false);
    });
  }

  // ADD THIS: save loan application to Firestore.
  Future<void> saveLoanApplication({
    required String applicationId,
    required String userId,
    required String userName,
    required String userEmail,
    required String userPhone,
    required String customerId,
    required String loanType,
    required int amount,
    required String period,
    required String duration,
    required String purpose,
  }) async {
    await _runWithTimeout(
      _loanApplications.doc(applicationId).set({
        'applicationId': applicationId,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'userPhone': userPhone,
        'customerId': customerId,
        'loanType': loanType,
        'amount': amount,
        'period': period,
        'duration': duration,
        'purpose': purpose,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }

  // ADD THIS: realtime loan applications stream for admin screen.
  Stream<List<Map<String, dynamic>>> streamLoanApplications() {
    return _loanApplications
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) {
                final data = doc.data();
                return <String, dynamic>{'id': doc.id, ...data};
              })
              .toList(growable: false);
        });
  }

  Stream<List<Map<String, dynamic>>> streamLoanApplicationsForUser(
    String userId,
  ) {
    return _loanApplications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) {
                final data = doc.data();
                return <String, dynamic>{'id': doc.id, ...data};
              })
              .toList(growable: false);
        });
  }

  // ADD THIS: approve/reject loan in Firestore.
  Future<void> updateLoanDecision({
    required String applicationId,
    required String status,
    required String adminId,
  }) async {
    await _runWithTimeout(
      _loanApplications.doc(applicationId).set({
        'status': status.toLowerCase(),
        'decisionAt': FieldValue.serverTimestamp(),
        'adminId': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }

  // ADD THIS: create in-app notification document.
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'info',
  }) async {
    final doc = _notifications.doc();
    await _runWithTimeout(
      doc.set({
        'id': doc.id,
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  // ADD THIS: notify all admins after a loan submission.
  Future<void> notifyAdminsLoanSubmitted({
    required String applicationId,
    required String applicantName,
    required int amount,
  }) async {
    final admins = await _runWithTimeout(
      _users.where('role', isEqualTo: 'admin').get(),
    );
    final futures = <Future<void>>[];

    for (final adminDoc in admins.docs) {
      futures.add(
        createNotification(
          userId: adminDoc.id,
          title: 'New Loan Application',
          message:
              '$applicantName submitted $applicationId for UGX $amount. Review required.',
          type: 'loan_submission',
        ),
      );
    }

    await _runWithTimeout(Future.wait(futures));
  }

  // ADD THIS: notify a single user after loan decision.
  Future<void> notifyLoanDecisionUser({
    required String userId,
    required String status,
  }) async {
    final cleanStatus = status.toLowerCase();
    await createNotification(
      userId: userId,
      title: cleanStatus == 'approved' ? 'Loan Approved' : 'Loan Rejected',
      message: cleanStatus == 'approved'
          ? 'Your loan application was approved.'
          : 'Your loan application was rejected.',
      type: 'loan',
    );
  }

  // ADD THIS: realtime notifications for current user.
  Stream<List<Map<String, dynamic>>> streamNotificationsForUser(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) {
                final data = doc.data();
                return <String, dynamic>{'id': doc.id, ...data};
              })
              .toList(growable: false);
        });
  }

  Future<void> markNotificationRead(String notificationId) async {
    if (notificationId.trim().isEmpty) return;
    await _runWithTimeout(
      _notifications.doc(notificationId).set({
        'read': true,
      }, SetOptions(merge: true)),
    );
  }

  Future<void> markAllNotificationsReadForUser(String userId) async {
    if (userId.trim().isEmpty) return;

    final unread = await _runWithTimeout(
      _notifications
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get(),
    );
    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.set(doc.reference, {'read': true}, SetOptions(merge: true));
    }
    await _runWithTimeout(batch.commit());
  }

  Future<String?> getRoleForUser(String uid) async {
    if (uid.trim().isEmpty) return null;
    final snap = await _runWithTimeout(_users.doc(uid).get());
    if (!snap.exists) return null;
    final role = _clean(snap.data()?['role']);
    return role?.toLowerCase();
  }

  Stream<Map<String, dynamic>?> streamUser(String uid) {
    return _users.doc(uid).snapshots().map((snap) => snap.data());
  }

  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) async {
    if (uid.trim().isEmpty) return;
    await _runWithTimeout(
      _users.doc(uid).set({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }

  Stream<List<Map<String, dynamic>>> streamTransactionsForUser(String userId) {
    return _transactions
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
              .toList(growable: false);
        });
  }

  Stream<Map<String, dynamic>?> streamActiveLoanForUser(String userId) {
    return _loans
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty ? snap.docs.first.data() : null);
  }

  Future<void> updateLoanInFirestore({
    required String userId,
    required String loanId,
    required Map<String, dynamic> data,
  }) async {
    final docId = 'loan_$userId';
    await _runWithTimeout(
      _loans.doc(docId).set({
        ...data,
        'userId': userId,
        'loanId': loanId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }

  Future<void> recordTransaction({
    required String userId,
    required String title,
    required String subtitle,
    required int amount,
    required bool isCredit,
  }) async {
    final userDoc = _users.doc(userId);
    final txDoc = _transactions.doc();

    await _runWithTimeout(
      _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userDoc);

        final currentBalance = userSnapshot.exists
            ? (userSnapshot.data()?['balanceValue'] ?? 0)
            : 0;
        final newBalance = isCredit
            ? currentBalance + amount
            : (currentBalance - amount).clamp(0, 1000000000);

        transaction.set(userDoc, {
          'balanceValue': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        transaction.set(txDoc, {
          'id': txDoc.id,
          'userId': userId,
          'title': title,
          'subtitle': subtitle,
          'amountValue': amount,
          'isCredit': isCredit,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }),
    );
  }

  Future<void> recordLoanRepayment({
    required String userId,
    required String loanId,
    required int amount,
  }) async {
    final userDoc = _users.doc(userId);
    final loanDoc = _loans.doc('loan_$userId');
    final txDoc = _transactions.doc();

    await _runWithTimeout(
      _firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userDoc);
        final loanSnapshot = await transaction.get(loanDoc);

        if (!userSnapshot.exists || !loanSnapshot.exists) {
          throw Exception("User or Loan record not found!");
        }

        final currentBalance = userSnapshot.data()?['balanceValue'] ?? 0;
        final currentRemaining =
            (loanSnapshot.data()?['remainingBalanceValue'] as num?)?.toInt() ??
            0;
        final amountBorrowed =
            (loanSnapshot.data()?['amountValue'] as num?)?.toInt() ??
            currentRemaining;

        final amountToApply = amount > currentRemaining
            ? currentRemaining
            : amount;
        final newRemaining = currentRemaining - amountToApply;
        final newBalance = (currentBalance - amountToApply).clamp(
          0,
          1000000000,
        );

        final safeBorrowed = amountBorrowed <= 0
            ? amountToApply
            : amountBorrowed;
        final paidSoFar = safeBorrowed - newRemaining;
        final progress = ((paidSoFar / safeBorrowed) * 100).round().clamp(
          0,
          100,
        );

        transaction.update(userDoc, {
          'balanceValue': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(loanDoc, {
          'remainingBalanceValue': newRemaining,
          'repaymentProgress': progress,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(txDoc, {
          'id': txDoc.id,
          'userId': userId,
          'title': 'Loan Repayment',
          'subtitle': 'Payment for $loanId',
          'amountValue': amountToApply,
          'isCredit': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }),
    );
  }

  String? _clean(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
