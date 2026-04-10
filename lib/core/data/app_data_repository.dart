import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:twezimbeapp/core/notifications/local_notification_service.dart';

class AppProfileData {
  const AppProfileData({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.nationalId,
    required this.address,
    required this.photoUrl,
    required this.customerId,
    required this.kycStatus,
    required this.accountType,
    required this.availableBalance,
    required this.isAdmin,
  });

  final String fullName;
  final String email;
  final String phoneNumber;
  final String dateOfBirth;
  final String nationalId;
  final String address;
  final String? photoUrl;
  final String customerId;
  final String kycStatus;
  final String accountType;
  final String availableBalance;
  final bool isAdmin;
}

class AppSecuritySettingsData {
  const AppSecuritySettingsData({
    required this.biometricEnabled,
    required this.twoFactorEnabled,
    required this.transactionAlerts,
    required this.loginAlerts,
  });

  final bool biometricEnabled;
  final bool twoFactorEnabled;
  final bool transactionAlerts;
  final bool loginAlerts;
}

class AppLoanData {
  const AppLoanData({
    required this.type,
    required this.loanId,
    required this.status,
    required this.remainingBalance,
    required this.nextPaymentDate,
    required this.repaymentProgress,
  });

  final String type;
  final String loanId;
  final String status;
  final String remainingBalance;
  final String nextPaymentDate;
  final String repaymentProgress;
}

class AppLoanApplicationData {
  const AppLoanApplicationData({
    required this.applicationId,
    required this.loanType,
    required this.amount,
    required this.period,
    required this.purpose,
    required this.status,
    required this.createdAt,
  });

  final String applicationId;
  final String loanType;
  final String amount;
  final String period;
  final String purpose;
  final String status;
  final DateTime? createdAt;
}

class AppTransactionData {
  const AppTransactionData({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
    this.createdAt,
  });

  final String title;
  final String subtitle;
  final String amount;
  final bool isCredit;
  final DateTime? createdAt;
}

class AppNotificationData {
  const AppNotificationData({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime? createdAt;
  final bool isRead;
}

class AppChatMessageData {
  const AppChatMessageData({
    required this.id,
    required this.conversationId,
    required this.isUser,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final bool isUser;
  final String text;
  final DateTime? createdAt;
}

class AppSupportData {
  const AppSupportData({
    required this.phone,
    required this.email,
    required this.liveChatHours,
    required this.appVersion,
    required this.buildNumber,
  });

  final String phone;
  final String email;
  final String liveChatHours;
  final String appVersion;
  final String buildNumber;
}

class AppFaqData {
  const AppFaqData({required this.question, required this.answer});

  final String question;
  final String answer;
}

class AppChatConversationData {
  const AppChatConversationData({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  final String id;
  final String title;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
}

class LoanApplicationException implements Exception {
  const LoanApplicationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppDataRepository {
  AppDataRepository._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  static AppSupportData support = const AppSupportData(
    phone: '+256 700 000 000',
    email: 'support@twezimbe.co.ug',
    liveChatHours: 'Available 8AM - 6PM',
    appVersion: '1.0.0',
    buildNumber: '2026.04.10',
  );

  static List<AppFaqData> faqs = const [
    AppFaqData(
      question: 'How do I apply for a loan?',
      answer:
          'Open the app, go to Loans, tap Apply for a New Loan, then complete the loan application form.',
    ),
    AppFaqData(
      question: 'How long does loan approval take?',
      answer:
          'Loan applications are reviewed within 24 hours. In some cases, extra verification can take up to 48 hours.',
    ),
    AppFaqData(
      question: 'What are the repayment options?',
      answer:
          'Repayment options include weekly, bi-weekly, and monthly schedules, with support for mobile money, bank transfer, or in-app repayment.',
    ),
    AppFaqData(
      question: 'How do I reset my password?',
      answer:
          'From the login screen, tap Forgot Password, enter your registered email or phone number, verify with the one-time code, then set a new password.',
    ),
    AppFaqData(
      question: 'Is my data secure?',
      answer:
          'Yes, Twezimbe uses encryption and regular system audits to help keep your personal and financial data secure.',
    ),
    AppFaqData(
      question: 'How do I check my account balance?',
      answer:
          'Check your balance on the home screen dashboard, or go to Profile > Personal Information to see detailed balance information.',
    ),
    AppFaqData(
      question: 'How do I update my profile picture?',
      answer:
          'Go to Profile, tap the camera icon on your profile photo, choose an image from your gallery, and it will be uploaded.',
    ),
    AppFaqData(
      question: 'What loan types are available?',
      answer:
          'Twezimbe offers Salary Loans, Business Loans, and Emergency Loans. Each has different terms and amounts. Visit Loans section for details.',
    ),
    AppFaqData(
      question: 'How do I make a deposit?',
      answer:
          'Go to the home screen and tap Deposit, or go to Transactions > Deposit. You can deposit via mobile money or bank transfer.',
    ),
    AppFaqData(
      question: 'How do I contact customer support?',
      answer:
          'Email: support@twezimbe.co.ug\nPhone: +256 700 000 000\nAvailable 8AM - 6PM daily.',
    ),
    AppFaqData(
      question: 'What is KYC verification?',
      answer:
          'KYC (Know Your Customer) is verification of your identity. Complete it by adding your National ID in Profile > Personal Information.',
    ),
    AppFaqData(
      question: 'How do I enable biometric login?',
      answer:
          'Go to Profile > Security Settings > Biometric Authentication and toggle it on. You can then use fingerprint or face to log in.',
    ),
  ];

  // Ensure user exists in Firestore database
  static Future<void> ensureProfileForCurrentUser({
    String? fullName,
    String? email,
    String? phoneNumber,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = _usersRef.doc(user.uid);
    final snapshot = await userRef.get();
    final existing = snapshot.data() ?? const <String, dynamic>{};
    final normalizedEmail =
        _nonEmpty(email)?.toLowerCase() ??
        _nonEmpty(user.email)?.toLowerCase() ??
        _nonEmpty(existing['email']) ??
        '';

    final payload = <String, dynamic>{
      'id': user.uid,
      'fullName':
          _nonEmpty(fullName) ??
          _nonEmpty(existing['fullName']) ??
          _displayNameFor(user),
      'email': normalizedEmail,
      'phoneNumber':
          _nonEmpty(phoneNumber) ??
          _nonEmpty(user.phoneNumber) ??
          _nonEmpty(existing['phoneNumber']) ??
          '',
      'dateOfBirth': _nonEmpty(existing['dateOfBirth']) ?? '',
      'nationalId': _nonEmpty(existing['nationalId']) ?? '',
      'address': _nonEmpty(existing['address']) ?? '',
      'photoUrl':
          _nonEmpty(existing['photoUrl']) ?? _nonEmpty(user.photoURL) ?? '',
      'customerId': _nonEmpty(existing['customerId']) ?? _customerIdFor(user),
      'kycStatus': _nonEmpty(existing['kycStatus']) ?? 'Pending',
      'accountType': _nonEmpty(existing['accountType']) ?? 'Savings Account',
      'balanceValue': _intFromDynamic(existing['balanceValue']),
      'isAdmin':
          _boolFromDynamic(existing['isAdmin']) ||
          _isAdminEmail(normalizedEmail),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }

    await userRef.set(payload, SetOptions(merge: true));
  }

  static Stream<AppProfileData> watchProfileForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream<AppProfileData>.empty();
    }

    unawaited(ensureProfileForCurrentUser().catchError((_) {}));

    return _usersRef.doc(user.uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) {
        return AppProfileData(
          fullName: _displayNameFor(user),
          email: user.email ?? '',
          phoneNumber: user.phoneNumber ?? 'Not set',
          dateOfBirth: 'Not set',
          nationalId: 'Not set',
          address: 'Not set',
          photoUrl: user.photoURL,
          customerId: _customerIdFor(user),
          kycStatus: 'Pending',
          accountType: 'Savings Account',
          availableBalance: 'UGX 0',
          isAdmin: _isAdminEmail(user.email),
        );
      }

      final balanceValue = _intFromDynamic(data['balanceValue']);
      return AppProfileData(
        fullName: _nonEmpty(data['fullName']) ?? _displayNameFor(user),
        email: _nonEmpty(data['email']) ?? (user.email ?? ''),
        phoneNumber:
            _nonEmpty(data['phoneNumber']) ?? (user.phoneNumber ?? 'Not set'),
        dateOfBirth: _nonEmpty(data['dateOfBirth']) ?? 'Not set',
        nationalId: _nonEmpty(data['nationalId']) ?? 'Not set',
        address: _nonEmpty(data['address']) ?? 'Not set',
        photoUrl: _nonEmpty(data['photoUrl']),
        customerId: _nonEmpty(data['customerId']) ?? _customerIdFor(user),
        kycStatus: _nonEmpty(data['kycStatus']) ?? 'Pending',
        accountType: _nonEmpty(data['accountType']) ?? 'Savings Account',
        availableBalance: _formatUgx(balanceValue),
        isAdmin: _boolFromDynamic(data['isAdmin']),
      );
    });
  }

  static Future<void> updatePersonalInfoForCurrentUser({
    required String fullName,
    required String phoneNumber,
    required String dateOfBirth,
    required String nationalId,
    required String address,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    await _usersRef.doc(user.uid).set({
      'fullName': fullName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'dateOfBirth': dateOfBirth.trim(),
      'nationalId': nationalId.trim(),
      'address': address.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> updateProfilePhotoUrlForCurrentUser(
    String photoUrl,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    await _usersRef.doc(user.uid).set({
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await user.updatePhotoURL(photoUrl);
    } catch (_) {
      // Ignore auth profile update failures
    }
  }

  static Future<String?> getCurrentProfilePhotoUrlForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    final data = (await _usersRef.doc(user.uid).get()).data();
    final profilePhotoUrl = _nonEmpty(data?['photoUrl']);

    if (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty) {
      return profilePhotoUrl;
    }

    final authPhotoUrl = user.photoURL?.trim();
    if (authPhotoUrl != null && authPhotoUrl.isNotEmpty) {
      return authPhotoUrl;
    }

    return null;
  }

  // Loan operations
  static Stream<AppLoanData> watchActiveLoanForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream<AppLoanData>.empty();
    }

    unawaited(ensureLoanForCurrentUser().catchError((_) {}));

    final activeLoanRef = _usersRef
        .doc(user.uid)
        .collection('loans')
        .doc('active');
    return activeLoanRef.snapshots().map((snapshot) {
      final loan = snapshot.data();
      unawaited(checkAndSendPaymentDueNotification().catchError((_) {}));

      if (loan == null) {
        return const AppLoanData(
          type: 'No Active Loan',
          loanId: 'N/A',
          status: 'None',
          remainingBalance: 'UGX 0',
          nextPaymentDate: 'Not scheduled',
          repaymentProgress: '0% Paid',
        );
      }

      return AppLoanData(
        type: _nonEmpty(loan['type']) ?? 'Salary Loan',
        loanId: _nonEmpty(loan['loanId']) ?? _loanIdFor(user),
        status: _nonEmpty(loan['status']) ?? 'Active',
        remainingBalance: _formatUgx(
          _intFromDynamic(loan['remainingBalanceValue']),
        ),
        nextPaymentDate: _nonEmpty(loan['nextPaymentDate']) ?? 'TBD',
        repaymentProgress:
            '${_intFromDynamic(loan['repaymentProgress'])}% Paid',
      );
    });
  }

  static Future<void> ensureLoanForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final loanRef = _usersRef.doc(user.uid).collection('loans').doc('active');
    final existing = await loanRef.get();
    if (existing.exists) {
      return;
    }

    await loanRef.set({
      'id': 'active',
      'userId': user.uid,
      'loanId': _loanIdFor(user),
      'type': 'Salary Loan',
      'status': 'None',
      'amountValue': 0,
      'remainingBalanceValue': 0,
      'period': '',
      'purpose': '',
      'nextPaymentDate': 'TBD',
      'repaymentProgress': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<List<AppLoanApplicationData>>
  watchLoanApplicationsForCurrentUser({int limit = 100}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<List<AppLoanApplicationData>>.value(
        const <AppLoanApplicationData>[],
      );
    }

    return _usersRef
        .doc(user.uid)
        .collection('loanApplications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                final amountValue = _intFromDynamic(data['amountValue']);
                return AppLoanApplicationData(
                  applicationId: _nonEmpty(data['applicationId']) ?? doc.id,
                  loanType: _nonEmpty(data['loanType']) ?? 'Loan',
                  amount: _formatUgx(amountValue),
                  period: _nonEmpty(data['period']) ?? '-',
                  purpose: _nonEmpty(data['purpose']) ?? '-',
                  status: _nonEmpty(data['status']) ?? 'Pending Review',
                  createdAt: _asDateTime(data['createdAt']),
                );
              })
              .toList(growable: false);
        });
  }

  static Future<AppLoanApplicationData> submitLoanApplicationForCurrentUser({
    required String loanType,
    required int amountValue,
    required String period,
    required String purpose,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    if (amountValue < 50000) {
      throw const LoanApplicationException(
        'Minimum loan amount is UGX 50,000.',
      );
    }
    if (amountValue > 200000000) {
      throw const LoanApplicationException(
        'Maximum loan amount is UGX 200,000,000.',
      );
    }

    await ensureProfileForCurrentUser();
    await ensureLoanForCurrentUser();

    // Check for pending applications
    final pendingQuery = await _usersRef
        .doc(user.uid)
        .collection('loanApplications')
        .where('status', isEqualTo: 'Pending Review')
        .limit(1)
        .get();
    final hasPending = pendingQuery.docs.isNotEmpty;
    if (hasPending) {
      throw const LoanApplicationException(
        'You already have a pending loan application. Please wait for review.',
      );
    }

    final userData = (await _usersRef.doc(user.uid).get()).data();
    final applicantName =
        _nonEmpty(userData?['fullName']) ?? _displayNameFor(user);
    final applicantEmail = _nonEmpty(userData?['email']) ?? (user.email ?? '');
    final applicantPhone =
        _nonEmpty(userData?['phoneNumber']) ?? (user.phoneNumber ?? '');
    final customerId = _nonEmpty(userData?['customerId']) ?? '';

    final applicationId = _applicationIdFor(user.uid);

    final appRef = _usersRef
        .doc(user.uid)
        .collection('loanApplications')
        .doc(applicationId);
    final activeLoanRef = _usersRef
        .doc(user.uid)
        .collection('loans')
        .doc('active');

    final batch = _firestore.batch();
    batch.set(appRef, {
      'id': applicationId,
      'applicationId': applicationId,
      'userId': user.uid,
      'userName': applicantName,
      'userEmail': applicantEmail,
      'userPhone': applicantPhone,
      'customerId': customerId,
      'loanType': loanType.trim(),
      'amountValue': amountValue,
      'period': period.trim(),
      'purpose': purpose.trim(),
      'status': 'Pending Review',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(activeLoanRef, {
      'id': 'active',
      'userId': user.uid,
      'loanId': _loanIdFor(user),
      'type': loanType.trim(),
      'status': 'Pending Review',
      'amountValue': amountValue,
      'remainingBalanceValue': amountValue,
      'period': period.trim(),
      'purpose': purpose.trim(),
      'nextPaymentDate': 'Awaiting approval',
      'repaymentProgress': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();

    await addNotificationForUser(
      userId: user.uid,
      title: 'Loan Application Successful',
      message: 'Loan application submitted and pending approval.',
      type: 'loan',
    );

    return AppLoanApplicationData(
      applicationId: applicationId,
      loanType: loanType.trim(),
      amount: _formatUgx(amountValue),
      period: period.trim(),
      purpose: purpose.trim(),
      status: 'Pending Review',
      createdAt: DateTime.now(),
    );
  }

  // Transactions
  static Stream<List<AppTransactionData>>
  watchRecentTransactionsForCurrentUser({int limit = 100}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<List<AppTransactionData>>.value(
        const <AppTransactionData>[],
      );
    }

    return _usersRef
        .doc(user.uid)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                final amountValue = _intFromDynamic(data['amountValue']);
                final isCredit = _boolFromDynamic(data['isCredit']);
                final sign = isCredit ? '+' : '-';
                final createdAt = _asDateTime(data['createdAt']);
                return AppTransactionData(
                  title: _nonEmpty(data['title']) ?? 'Transaction',
                  subtitle: createdAt != null
                      ? _relativeTimeLabel(createdAt)
                      : 'Just now',
                  amount: '$sign ${_formatUgx(amountValue)}',
                  isCredit: isCredit,
                  createdAt: createdAt,
                );
              })
              .toList(growable: false);
        });
  }

  static Future<void> addTransactionForCurrentUser({
    required String title,
    required String subtitle,
    required int amountValue,
    required bool isCredit,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    await ensureProfileForCurrentUser();

    final userRef = _usersRef.doc(user.uid);
    final txRef = userRef
        .collection('transactions')
        .doc('tx_${DateTime.now().millisecondsSinceEpoch}');

    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final currentBalance = _intFromDynamic(
        userSnapshot.data()?['balanceValue'],
      );
      final nextBalance = isCredit
          ? currentBalance + amountValue
          : (currentBalance - amountValue).clamp(0, 999999999);

      transaction.set(userRef, {
        'balanceValue': nextBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(txRef, {
        'id': txRef.id,
        'userId': user.uid,
        'title': title,
        'subtitle': subtitle,
        'amountValue': amountValue,
        'isCredit': isCredit,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    final flow = isCredit ? 'deposit' : 'withdrawal';
    await addNotificationForCurrentUser(
      title: isCredit ? 'Deposit Successful' : 'Withdrawal Successful',
      message:
          'Your $flow of ${_formatUgx(amountValue)} was completed successfully.',
      type: isCredit ? 'deposit' : 'withdrawal',
    );
  }

  // Notifications
  static Stream<List<AppNotificationData>> watchNotificationsForCurrentUser({
    int limit = 100,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<List<AppNotificationData>>.value(
        const <AppNotificationData>[],
      );
    }

    return _usersRef
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                final data = doc.data();
                return AppNotificationData(
                  id: doc.id,
                  title: _nonEmpty(data['title']) ?? 'Notification',
                  message: _nonEmpty(data['message']) ?? '',
                  type: _nonEmpty(data['type']) ?? 'info',
                  createdAt: _asDateTime(data['createdAt']),
                  isRead: _boolFromDynamic(data['isRead']),
                );
              })
              .toList(growable: false);
        });
  }

  static Future<void> addNotificationForCurrentUser({
    required String title,
    required String message,
    String type = 'info',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    await addNotificationForUser(
      userId: user.uid,
      title: title,
      message: message,
      type: type,
    );

    unawaited(
      LocalNotificationService.showNotification(
        title: title,
        body: message,
        payload: type,
      ).catchError((_) {}),
    );
  }

  static Future<void> markNotificationAsReadForCurrentUser(
    String notificationId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _usersRef
        .doc(user.uid)
        .collection('notifications')
        .doc(notificationId)
        .set({'isRead': true}, SetOptions(merge: true));
  }

  static Future<void> markAllNotificationsAsReadForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final unreadDocs = await _usersRef
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    if (unreadDocs.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    for (final doc in unreadDocs.docs) {
      batch.set(doc.reference, {'isRead': true}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  // Admin operations
  static Future<bool> isCurrentUserAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    if (_isAdminEmail(user.email)) return true;

    final userData = (await _usersRef.doc(user.uid).get()).data();
    return _boolFromDynamic(userData?['isAdmin']);
  }

  static Future<void> setUserAdminRole(String userId, bool isAdmin) async {
    await _usersRef.doc(userId).set({
      'isAdmin': isAdmin,
    }, SetOptions(merge: true));
  }

  static Stream<List<AppProfileData>> watchAllUsers() {
    return _usersRef.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return AppProfileData(
              fullName: _nonEmpty(data['fullName']) ?? 'Unknown',
              email: _nonEmpty(data['email']) ?? '',
              phoneNumber: _nonEmpty(data['phoneNumber']) ?? 'Not set',
              dateOfBirth: _nonEmpty(data['dateOfBirth']) ?? 'Not set',
              nationalId: _nonEmpty(data['nationalId']) ?? 'Not set',
              address: _nonEmpty(data['address']) ?? 'Not set',
              photoUrl: _nonEmpty(data['photoUrl']),
              customerId: _nonEmpty(data['customerId']) ?? '',
              kycStatus: _nonEmpty(data['kycStatus']) ?? 'Pending',
              accountType: _nonEmpty(data['accountType']) ?? 'Savings Account',
              availableBalance: _formatUgx(
                _intFromDynamic(data['balanceValue']),
              ),
              isAdmin: _boolFromDynamic(data['isAdmin']),
            );
          })
          .toList(growable: false);
    });
  }

  static Future<int> getTotalUsersCount() async {
    final aggregate = await _usersRef.count().get();
    return aggregate.count ?? 0;
  }

  static Future<int> getPendingLoansCount() async {
    final aggregate = await _firestore
        .collectionGroup('loanApplications')
        .where('status', isEqualTo: 'Pending Review')
        .count()
        .get();
    return aggregate.count ?? 0;
  }

  // Admin: Approve loan
  static Future<void> approveLoanApplication(
    String userId,
    String applicationId, {
    String? loanDocumentId,
  }) async {
    final userRef = _usersRef.doc(userId);
    final appRef = userRef
        .collection('loanApplications')
        .doc(_nonEmpty(loanDocumentId) ?? applicationId);
    final loanRef = userRef.collection('loans').doc('active');

    final userData = (await userRef.get()).data();
    if (userData == null) throw StateError('User not found');

    final app = (await appRef.get()).data();
    if (app == null) throw StateError('Loan application not found');

    final loanAmount = _intFromDynamic(app['amountValue']);
    final admin = FirebaseAuth.instance.currentUser;
    final reviewer = admin?.email ?? 'admin';

    final txRef = userRef
        .collection('transactions')
        .doc('tx_${DateTime.now().millisecondsSinceEpoch}');

    final batch = _firestore.batch();
    batch.set(appRef, {
      'status': 'Approved',
      'reviewedBy': reviewer,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(loanRef, {
      'id': 'active',
      'userId': userId,
      'loanId': _nonEmpty(app['loanId']) ?? _loanIdFor(null),
      'type': _nonEmpty(app['loanType']) ?? 'Loan',
      'status': 'Active',
      'amountValue': loanAmount,
      'remainingBalanceValue': loanAmount,
      'period': _nonEmpty(app['period']) ?? '',
      'purpose': _nonEmpty(app['purpose']) ?? '',
      'nextPaymentDate': _nextPaymentDateLabel(),
      'repaymentProgress': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(userRef, {
      'balanceValue': FieldValue.increment(loanAmount),
      'lastDueReminderKey': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(txRef, {
      'id': txRef.id,
      'userId': userId,
      'title': 'Loan Disbursed',
      'subtitle': 'Loan approved and credited to account',
      'amountValue': loanAmount,
      'isCredit': true,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();

    // Notify user
    await addNotificationForUser(
      userId: userId,
      title: 'Loan Approved',
      message:
          'Your loan of ${_formatUgx(loanAmount)} has been approved and credited to your account!',
      type: 'loan',
    );
  }

  // Admin: Reject loan
  static Future<void> rejectLoanApplication(
    String userId,
    String applicationId,
    String reason, {
    String? loanDocumentId,
  }) async {
    final userRef = _usersRef.doc(userId);
    final appRef = userRef
        .collection('loanApplications')
        .doc(_nonEmpty(loanDocumentId) ?? applicationId);
    final loanRef = userRef.collection('loans').doc('active');

    final admin = FirebaseAuth.instance.currentUser;
    final reviewer = admin?.email ?? 'admin';
    final rejectionReason = reason.trim().isEmpty
        ? 'Please contact support for guidance.'
        : reason.trim();

    final batch = _firestore.batch();
    batch.set(appRef, {
      'status': 'Rejected',
      'rejectionReason': rejectionReason,
      'reviewedBy': reviewer,
      'reviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(loanRef, {
      'status': 'Rejected',
      'nextPaymentDate': 'Awaiting new application',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();

    // Notify user
    await addNotificationForUser(
      userId: userId,
      title: 'Loan Rejected',
      message:
          'Your loan application has been rejected. Reason: $rejectionReason',
      type: 'loan',
    );
  }

  static Future<void> addNotificationForUser({
    required String userId,
    required String title,
    required String message,
    String type = 'info',
  }) async {
    final notifRef = _usersRef
        .doc(userId)
        .collection('notifications')
        .doc('notif_${DateTime.now().millisecondsSinceEpoch}');
    await notifRef.set({
      'id': notifRef.id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> makeLoanRepaymentForCurrentUser({
    required int amountValue,
    required String method,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }
    if (amountValue <= 0) {
      throw ArgumentError('Payment amount must be greater than zero.');
    }

    final userRef = _usersRef.doc(user.uid);
    final loanRef = userRef.collection('loans').doc('active');
    final txRef = userRef
        .collection('transactions')
        .doc('tx_${DateTime.now().millisecondsSinceEpoch}');

    int remainingAfterPayment = 0;

    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final loanSnapshot = await transaction.get(loanRef);

      if (!loanSnapshot.exists) {
        throw StateError('No active loan found.');
      }

      final loanData = loanSnapshot.data() ?? const <String, dynamic>{};
      final status = _nonEmpty(loanData['status']) ?? 'None';
      if (status != 'Active' && status != 'Approved') {
        throw StateError('Loan is not available for repayment.');
      }

      final amountBorrowed = _intFromDynamic(loanData['amountValue']);
      final currentRemaining = _intFromDynamic(
        loanData['remainingBalanceValue'],
      );
      if (currentRemaining <= 0) {
        throw StateError('Loan is already fully paid.');
      }

      final amountToApply = amountValue > currentRemaining
          ? currentRemaining
          : amountValue;
      remainingAfterPayment = currentRemaining - amountToApply;

      final safeBorrowed = amountBorrowed <= 0
          ? currentRemaining
          : amountBorrowed;
      final paidSoFar = safeBorrowed - remainingAfterPayment;
      final progress = ((paidSoFar / safeBorrowed) * 100).round().clamp(0, 100);

      final currentBalance = _intFromDynamic(
        userSnapshot.data()?['balanceValue'],
      );
      final nextBalance = (currentBalance - amountToApply).clamp(0, 999999999);

      transaction.set(userRef, {
        'balanceValue': nextBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(loanRef, {
        'remainingBalanceValue': remainingAfterPayment,
        'repaymentProgress': progress,
        'status': remainingAfterPayment <= 0 ? 'Paid Off' : 'Active',
        'nextPaymentDate': remainingAfterPayment <= 0
            ? 'N/A'
            : _nextPaymentDateLabel(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(txRef, {
        'id': txRef.id,
        'userId': user.uid,
        'title': 'Loan Repayment',
        'subtitle': 'Payment via $method',
        'amountValue': amountToApply,
        'isCredit': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    if (remainingAfterPayment <= 0) {
      await addNotificationForCurrentUser(
        title: 'Loan Paid Off',
        message: 'Congratulations! You have fully paid your loan.',
        type: 'loan',
      );
    } else {
      await addNotificationForCurrentUser(
        title: 'Repayment Received',
        message:
            'We have received your repayment. Outstanding balance is ${_formatUgx(remainingAfterPayment)}.',
        type: 'loan',
      );
    }
  }

  // Helper methods
  static bool _isAdminEmail(String? email) {
    if (email == null) return false;
    return email.toLowerCase().trim() == 'admin@twezimbe.co.ug';
  }

  static String _displayNameFor(User? user) {
    final name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return 'Member';
  }

  static String _customerIdFor(User? user) {
    final source = user?.uid ?? user?.email ?? '00001';
    final normalized = source.codeUnits.fold<int>(0, (a, b) => a + b) % 99999;
    final padded = normalized.toString().padLeft(5, '0');
    return 'CUS$padded';
  }

  static String _loanIdFor(User? user) {
    final source = (user?.uid ?? user?.email ?? 'loan').toUpperCase();
    final compact = source.replaceAll(RegExp(r'[^A-Z0-9]'), 'X');
    final eight = compact.padRight(8, 'X').substring(0, 8);
    return eight;
  }

  static String _applicationIdFor(String userId) {
    final hash = userId.codeUnits.fold<int>(0, (a, b) => (a + b) % 10000);
    final suffix = hash.toString().padLeft(4, '0');
    return 'APP${DateTime.now().millisecondsSinceEpoch}$suffix';
  }

  static String _nextPaymentDateLabel() {
    final dueDate = DateTime.now().add(const Duration(days: 30));
    final day = dueDate.day.toString().padLeft(2, '0');
    final month = dueDate.month.toString().padLeft(2, '0');
    return '$day/$month/${dueDate.year}';
  }

  static String _relativeTimeLabel(DateTime dateTime) {
    final delta = DateTime.now().difference(dateTime);
    if (delta.inSeconds < 60) return 'Just now';
    if (delta.inMinutes < 60) return '${delta.inMinutes} min ago';
    if (delta.inHours < 24) return '${delta.inHours} hr ago';
    if (delta.inDays < 7) return '${delta.inDays} day ago';
    final weeks = (delta.inDays / 7).floor();
    if (weeks < 5) return '$weeks wk ago';
    final months = (delta.inDays / 30).floor();
    if (months < 12) return '$months mo ago';
    final years = (delta.inDays / 365).floor();
    return '$years yr ago';
  }

  static String _formatUgx(int amount) {
    final String digits = amount.toString();
    final StringBuffer formatted = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final int idxFromEnd = digits.length - i;
      formatted.write(digits[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        formatted.write(',');
      }
    }
    return 'UGX ${formatted.toString()}';
  }

  static String formatUgx(int amount) => _formatUgx(amount);

  // ============ CHAT METHODS ============

  static Future<String>
  getOrCreateActiveChatConversationIdForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user found.');
    return 'chat_${user.uid}';
  }

  static Future<void> addChatMessageForCurrentUser({
    required String conversationId,
    required String text,
    required bool isUser,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user found.');

    // Note: In a real app, you'd insert to a chat_messages table
    // For now, this is a stub
  }

  static Future<void> updateChatMessageForCurrentUser({
    required String messageId,
    required String text,
  }) async {
    // Stub - update chat message
  }

  static Future<void> deleteChatMessageForCurrentUser(String messageId) async {
    // Stub - delete chat message
  }

  static Future<String> startNewChatForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user found.');
    return 'chat_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
  }

  static Future<int> deletePreviousChatConversationsForCurrentUser({
    required String keepConversationId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user found.');
    // Stub - delete old conversations
    return 0;
  }

  static Future<void> setActiveChatConversationIdForCurrentUser(
    String conversationId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user found.');
    // Stub - set active conversation
  }

  static Stream<String?> watchActiveChatConversationIdForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream<String?>.empty();
    return Stream.value('chat_${user.uid}');
  }

  static Stream<List<AppChatMessageData>> watchChatMessagesForCurrentUser({
    required String conversationId,
  }) {
    return Stream.value(const <AppChatMessageData>[]);
  }

  static Stream<List<AppChatConversationData>>
  watchChatConversationsForCurrentUser() {
    return Stream.value(const <AppChatConversationData>[]);
  }

  // ============ SECURITY SETTINGS METHODS ============

  static Future<void> updateSecuritySettingsForCurrentUser({
    required bool biometricEnabled,
    required bool twoFactorEnabled,
    required bool transactionAlerts,
    required bool loginAlerts,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user found.');
    // Stub - save to SQLite in a security_settings table
  }

  static Stream<AppSecuritySettingsData> watchSecuritySettingsForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream<AppSecuritySettingsData>.empty();
    }
    return Stream.value(
      const AppSecuritySettingsData(
        biometricEnabled: false,
        twoFactorEnabled: false,
        transactionAlerts: true,
        loginAlerts: true,
      ),
    );
  }

  // ============ PAYMENT DUE NOTIFICATION CHECK ============

  /// Check if loan payment is due within 2 days and send notification if needed
  static Future<void> checkAndSendPaymentDueNotification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userRef = _usersRef.doc(user.uid);
      final userDoc = await userRef.get();
      final userData = userDoc.data();
      if (userData == null) return;

      final loanDoc = await userRef.collection('loans').doc('active').get();
      final loan = loanDoc.data();
      if (loan == null) return;

      final status = _nonEmpty(loan['status']) ?? '';
      if (status != 'Active') return;

      final remainingBalance = _intFromDynamic(loan['remainingBalanceValue']);
      if (remainingBalance <= 0) return;

      // Parse next payment date
      final nextPaymentDateStr = _nonEmpty(loan['nextPaymentDate']) ?? '';
      if (nextPaymentDateStr == 'TBD' ||
          nextPaymentDateStr == 'N/A' ||
          nextPaymentDateStr == 'Awaiting approval' ||
          nextPaymentDateStr.isEmpty) {
        return;
      }

      final parts = nextPaymentDateStr.split('/');
      if (parts.length != 3) return;

      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day == null || month == null || year == null) return;

      final dueDate = DateTime(year, month, day);
      final daysUntilDue = dueDate.difference(DateTime.now()).inDays;

      if (daysUntilDue >= 0 && daysUntilDue <= 2) {
        final reminderKey =
            '${_nonEmpty(loan['loanId']) ?? 'active'}|$nextPaymentDateStr|$daysUntilDue';
        if (_nonEmpty(userData['lastDueReminderKey']) == reminderKey) {
          return;
        }

        await addNotificationForUser(
          userId: user.uid,
          title: 'Loan Payment Due Soon',
          message: daysUntilDue == 0
              ? 'Your loan payment is due TODAY!'
              : 'Your loan payment is due in $daysUntilDue day${daysUntilDue == 1 ? '' : 's'}.',
          type: 'reminder',
        );

        await userRef.set({
          'lastDueReminderKey': reminderKey,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      developer.log(
        'Error checking payment due notification: $e',
        name: 'AppDataRepository',
      );
    }
  }

  static String? _nonEmpty(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int _intFromDynamic(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static bool _boolFromDynamic(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
