import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twezimbeapp/core/data/change_bus.dart';
import 'package:twezimbeapp/core/data/database_helper.dart';
import 'package:twezimbeapp/core/data/db_constants.dart';
import 'package:twezimbeapp/core/data/repository_registry.dart';
import 'package:twezimbeapp/core/data/models/ledger_entry_model.dart';
import 'package:twezimbeapp/core/data/models/loan_application_model.dart';
import 'package:twezimbeapp/core/data/models/loan_model.dart';
import 'package:twezimbeapp/core/data/models/loan_repayment_model.dart';
import 'package:twezimbeapp/core/data/models/deposit_model.dart';
import 'package:twezimbeapp/core/data/models/withdrawal_model.dart';
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

  static final DatabaseHelper _db = DatabaseHelper();
  static final DatabaseChangeBus _bus = DatabaseChangeBus.instance;
  static final _loanRepository = RepositoryRegistry.loanRepository;
  static final _depositRepository = RepositoryRegistry.depositRepository;
  static final _withdrawalRepository = RepositoryRegistry.withdrawalRepository;
  static const Duration _pollInterval = Duration(milliseconds: 900);

  static const String _chatMessagesPrefix = 'chat_messages_';
  static const String _chatConversationsPrefix = 'chat_conversations_';
  static const String _chatActiveConversationPrefix =
      'chat_active_conversation_';
  static const String _securitySettingsPrefix = 'security_settings_';
  static const String _dueReminderPrefix = 'loan_due_reminder_';

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

  static Future<void> ensureProfileForCurrentUser({
    String? fullName,
    String? email,
    String? phoneNumber,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nowIso = DateTime.now().toIso8601String();
    final existing = await _db.getUser(user.uid);

    final normalizedEmail =
        _nonEmpty(email)?.toLowerCase() ??
        _nonEmpty(user.email)?.toLowerCase() ??
        _nonEmpty(existing?['email']) ??
        '';

    final payload = <String, dynamic>{
      'id': user.uid,
      'fullName':
          _nonEmpty(fullName) ??
          _nonEmpty(existing?['fullName']) ??
          _displayNameFor(user),
      'email': normalizedEmail,
      'phoneNumber':
          _nonEmpty(phoneNumber) ??
          _nonEmpty(user.phoneNumber) ??
          _nonEmpty(existing?['phoneNumber']) ??
          '',
      'dateOfBirth': _nonEmpty(existing?['dateOfBirth']) ?? '',
      'nationalId': _nonEmpty(existing?['nationalId']) ?? '',
      'address': _nonEmpty(existing?['address']) ?? '',
      'photoUrl':
          _nonEmpty(existing?['photoUrl']) ?? _nonEmpty(user.photoURL) ?? '',
      'customerId': _nonEmpty(existing?['customerId']) ?? _customerIdFor(user),
      'kycStatus': _nonEmpty(existing?['kycStatus']) ?? 'Pending',
      'accountType': _nonEmpty(existing?['accountType']) ?? 'Savings Account',
      'balanceValue': _intFromDynamic(existing?['balanceValue']),
      'isAdmin':
          _boolFromDynamic(existing?['isAdmin']) ||
              _isAdminEmail(normalizedEmail)
          ? 1
          : 0,
      'updatedAt': nowIso,
    };

    if (existing == null) {
      payload['createdAt'] = nowIso;
      await _db.insertUser(payload);
    } else {
      await _db.updateUser(user.uid, payload);
    }

    await _ensureDefaultAccountForUser(
      user.uid,
      _nonEmpty(payload['accountType']) ?? 'Savings Account',
    );
    _bus.notify(DbTables.users);
  }

  static Stream<AppProfileData> watchProfileForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream<AppProfileData>.empty();
    }

    unawaited(ensureProfileForCurrentUser().catchError((_) {}));

    final controller = StreamController<AppProfileData>();

    Future<void> emitLocalProfile() async {
      final row = await _db.getUser(user.uid);
      if (row == null) {
        controller.add(
          AppProfileData(
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
          ),
        );
        return;
      }
      controller.add(_profileFromLocalRow(row, user));
    }

    StreamSubscription<String>? sub;
    controller.onListen = () {
      unawaited(emitLocalProfile());
      sub = _bus.stream.where((table) => table == DbTables.users).listen((_) {
        unawaited(emitLocalProfile());
      });
    };

    controller.onCancel = () async {
      await sub?.cancel();
    };

    return controller.stream;
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

    final nowIso = DateTime.now().toIso8601String();
    await _db.updateUser(user.uid, {
      'fullName': fullName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'dateOfBirth': dateOfBirth.trim(),
      'nationalId': nationalId.trim(),
      'address': address.trim(),
      'updatedAt': nowIso,
    });
    _bus.notify(DbTables.users);
  }

  static Future<void> updateProfilePhotoUrlForCurrentUser(
    String photoUrl,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    final nowIso = DateTime.now().toIso8601String();
    await _db.updateUser(user.uid, {'photoUrl': photoUrl, 'updatedAt': nowIso});
    _bus.notify(DbTables.users);

    try {
      await user.updatePhotoURL(photoUrl);
    } catch (_) {
      // Ignore auth profile update failures.
    }
  }

  static Future<String?> getCurrentProfilePhotoUrlForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    final data = await _db.getUser(user.uid);
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

  static Stream<AppLoanData> watchActiveLoanForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream<AppLoanData>.empty();
    }

    unawaited(ensureLoanForCurrentUser().catchError((_) {}));

    return _loanRepository.watchActiveLoan(user.uid).map((loan) {
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
        type: loan.type.isNotEmpty ? loan.type : 'Salary Loan',
        loanId: loan.loanId.isNotEmpty ? loan.loanId : _loanIdFor(user),
        status: loan.status.isNotEmpty ? loan.status : DbStatus.active,
        remainingBalance: _formatUgx(loan.remainingBalanceValue),
        nextPaymentDate: loan.nextPaymentDate.isNotEmpty
            ? loan.nextPaymentDate
            : 'TBD',
        repaymentProgress: '${loan.repaymentProgress}% Paid',
      );
    });
  }

  static Future<void> ensureLoanForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final existing = await _db.getLatestLoanForUser(user.uid);
    if (existing != null) {
      return;
    }

    final nowIso = DateTime.now().toIso8601String();
    await _db.insertLoan({
      'id': 'loan_${user.uid}',
      'userId': user.uid,
      'loanId': _loanIdFor(user),
      'type': 'Salary Loan',
      'status': DbStatus.none,
      'amountValue': 0,
      'remainingBalanceValue': 0,
      'period': '',
      'purpose': '',
      'nextPaymentDate': 'TBD',
      'repaymentProgress': 0,
      'createdAt': nowIso,
      'updatedAt': nowIso,
    });
  }

  static Stream<List<AppLoanApplicationData>>
  watchLoanApplicationsForCurrentUser({int limit = 100}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<List<AppLoanApplicationData>>.value(
        const <AppLoanApplicationData>[],
      );
    }

    return _loanRepository.watchLoanApplications(user.uid, limit: limit).map((
      rows,
    ) {
      return rows
          .take(limit)
          .map((application) {
            final status = _normalizeLoanApplicationStatus(application.status);
            final createdAt = _asDateTime(application.createdAt);
            return AppLoanApplicationData(
              applicationId: application.applicationId,
              loanType: application.loanType.isNotEmpty
                  ? application.loanType
                  : 'Loan',
              amount: _formatUgx(application.amountValue),
              period: application.period.isNotEmpty ? application.period : '-',
              purpose: application.purpose.isNotEmpty
                  ? application.purpose
                  : '-',
              status: status,
              createdAt: createdAt,
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

    final existingApplications = await _db.getLoanApplications(user.uid);
    final hasPending = existingApplications.any((row) {
      final status = _nonEmpty(row['status']) ?? '';
      return status == DbStatus.pending || status == 'Pending Review';
    });
    if (hasPending) {
      throw const LoanApplicationException(
        'You already have a pending loan application. Please wait for review.',
      );
    }

    final userData = await _db.getUser(user.uid);
    final applicantName =
        _nonEmpty(userData?['fullName']) ?? _displayNameFor(user);
    final applicantEmail = _nonEmpty(userData?['email']) ?? (user.email ?? '');
    final applicantPhone =
        _nonEmpty(userData?['phoneNumber']) ?? (user.phoneNumber ?? '');
    final customerId = _nonEmpty(userData?['customerId']) ?? '';

    final applicationId = _applicationIdFor(user.uid);
    final nowIso = DateTime.now().toIso8601String();

    final application = LoanApplicationModel(
      id: applicationId,
      applicationId: applicationId,
      userId: user.uid,
      userName: applicantName,
      userEmail: applicantEmail,
      userPhone: applicantPhone,
      customerId: customerId,
      loanType: loanType.trim(),
      amountValue: amountValue,
      period: period.trim(),
      purpose: purpose.trim(),
      status: DbStatus.pending,
      rejectionReason: '',
      reviewedBy: '',
      reviewedAt: nowIso,
      createdAt: nowIso,
      updatedAt: nowIso,
      version: 0,
      syncStatus: DbSyncStatus.pendingSync,
    );
    await _loanRepository.upsertLoanApplication(application);

    final currentLoan = await _db.getLatestLoanForUser(user.uid);
    final loanPayload = LoanModel(
      id: currentLoan?['id']?.toString() ?? 'loan_${user.uid}',
      userId: user.uid,
      loanId: _loanIdFor(user),
      type: loanType.trim(),
      status: DbStatus.pending,
      amountValue: amountValue,
      remainingBalanceValue: amountValue,
      period: period.trim(),
      purpose: purpose.trim(),
      nextPaymentDate: 'Awaiting approval',
      repaymentProgress: 0,
      createdAt: currentLoan?['createdAt']?.toString() ?? nowIso,
      updatedAt: nowIso,
      version: _intFromDynamic(currentLoan?['version']),
      syncStatus: DbSyncStatus.pendingSync,
    );
    await _loanRepository.upsertLoan(loanPayload);

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

  static Stream<List<AppTransactionData>>
  watchRecentTransactionsForCurrentUser({int limit = 100}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<List<AppTransactionData>>.value(
        const <AppTransactionData>[],
      );
    }

    final controller = StreamController<List<AppTransactionData>>();

    Future<void> emitLocalTransactions() async {
      final rows = await _db.getTransactions(user.uid, limit: limit);
      controller.add(
        rows
            .map((row) => _transactionFromLocalRow(row))
            .toList(growable: false),
      );
    }

    StreamSubscription<String>? sub;
    controller.onListen = () {
      unawaited(emitLocalTransactions());
      sub = _bus.stream
          .where((table) => table == DbTables.transactions)
          .listen((_) => unawaited(emitLocalTransactions()));
    };

    controller.onCancel = () async {
      await sub?.cancel();
    };

    return controller.stream;
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

    final nowIso = DateTime.now().toIso8601String();
    final localUser = await _db.getUser(user.uid);
    final currentBalance = _intFromDynamic(localUser?['balanceValue']);
    final newBalance = isCredit
        ? currentBalance + amountValue
        : (currentBalance - amountValue).clamp(0, 1000000000);

    await _db.updateUser(user.uid, {
      'balanceValue': newBalance,
      'updatedAt': nowIso,
    });

    _bus.notify(DbTables.users);

    final accountType =
        _nonEmpty(localUser?['accountType']) ?? 'Savings Account';
    await _updateAccountBalance(
      userId: user.uid,
      accountType: accountType,
      balanceValue: newBalance,
    );

    final txId = 'tx_${DateTime.now().microsecondsSinceEpoch}';
    await _db.insertTransaction({
      'id': txId,
      'userId': user.uid,
      'title': title,
      'subtitle': subtitle,
      'amountValue': amountValue,
      'isCredit': isCredit ? 1 : 0,
      'createdAt': nowIso,
      'updatedAt': nowIso,
    });
    _bus.notify(DbTables.transactions);

    final accountId = await _getOrCreateAccountId(user.uid, accountType);
    if (isCredit) {
      final depositId = 'dep_${DateTime.now().microsecondsSinceEpoch}';
      await _depositRepository.insertDeposit(
        DepositModel(
          id: depositId,
          userId: user.uid,
          accountId: accountId,
          amountValue: amountValue,
          method: DbDefaults.depositMethod,
          status: DbStatus.completed,
          reference: txId,
          createdAt: nowIso,
          updatedAt: nowIso,
          version: 0,
          syncStatus: DbSyncStatus.pendingSync,
        ),
      );
      await _depositRepository.insertLedgerEntries([
        LedgerEntryModel(
          id: 'led_${depositId}_cr',
          userId: user.uid,
          accountId: accountId,
          amountValue: amountValue,
          entryType: DbEntryType.credit,
          referenceType: DbReferenceType.deposit,
          referenceId: depositId,
          createdAt: nowIso,
          updatedAt: nowIso,
          version: 0,
          syncStatus: DbSyncStatus.pendingSync,
        ),
        LedgerEntryModel(
          id: 'led_${depositId}_dr',
          userId: user.uid,
          accountId: null,
          amountValue: amountValue,
          entryType: DbEntryType.debit,
          referenceType: DbReferenceType.deposit,
          referenceId: depositId,
          createdAt: nowIso,
          updatedAt: nowIso,
          version: 0,
          syncStatus: DbSyncStatus.pendingSync,
        ),
      ]);
    } else {
      final withdrawalId = 'wd_${DateTime.now().microsecondsSinceEpoch}';
      await _withdrawalRepository.insertWithdrawal(
        WithdrawalModel(
          id: withdrawalId,
          userId: user.uid,
          accountId: accountId,
          amountValue: amountValue,
          method: DbDefaults.withdrawalMethod,
          status: DbStatus.completed,
          reference: txId,
          requestedAt: nowIso,
          processedAt: nowIso,
          createdAt: nowIso,
          updatedAt: nowIso,
          version: 0,
          syncStatus: DbSyncStatus.pendingSync,
        ),
      );
      await _withdrawalRepository.insertLedgerEntries([
        LedgerEntryModel(
          id: 'led_${withdrawalId}_dr',
          userId: user.uid,
          accountId: accountId,
          amountValue: amountValue,
          entryType: DbEntryType.debit,
          referenceType: DbReferenceType.withdrawal,
          referenceId: withdrawalId,
          createdAt: nowIso,
          updatedAt: nowIso,
          version: 0,
          syncStatus: DbSyncStatus.pendingSync,
        ),
        LedgerEntryModel(
          id: 'led_${withdrawalId}_cr',
          userId: user.uid,
          accountId: null,
          amountValue: amountValue,
          entryType: DbEntryType.credit,
          referenceType: DbReferenceType.withdrawal,
          referenceId: withdrawalId,
          createdAt: nowIso,
          updatedAt: nowIso,
          version: 0,
          syncStatus: DbSyncStatus.pendingSync,
        ),
      ]);
    }

    final flow = isCredit ? 'deposit' : 'withdrawal';
    unawaited(
      addNotificationForCurrentUser(
        title: isCredit ? 'Deposit Successful' : 'Withdrawal Successful',
        message:
            'Your $flow of ${_formatUgx(amountValue)} was completed successfully.',
        type: isCredit ? 'deposit' : 'withdrawal',
      ).catchError((error) {
        developer.log(
          'addNotificationForCurrentUser failed: $error',
          name: 'AppDataRepository.addTransactionForCurrentUser',
        );
      }),
    );
  }

  static Stream<List<AppNotificationData>> watchNotificationsForCurrentUser({
    int limit = 100,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<List<AppNotificationData>>.value(
        const <AppNotificationData>[],
      );
    }

    final controller = StreamController<List<AppNotificationData>>();

    Future<void> emitLocalNotifications() async {
      final rows = await _db.getNotifications(user.uid, limit: limit);
      controller.add(
        rows
            .map((row) {
              return AppNotificationData(
                id: _nonEmpty(row['id']) ?? '',
                title: _nonEmpty(row['title']) ?? 'Notification',
                message: _nonEmpty(row['message']) ?? '',
                type: _nonEmpty(row['type']) ?? 'info',
                createdAt: _asDateTime(row['createdAt']),
                isRead: _boolFromDynamic(row['isRead']),
              );
            })
            .toList(growable: false),
      );
    }

    StreamSubscription<String>? sub;
    controller.onListen = () {
      unawaited(emitLocalNotifications());
      sub = _bus.stream
          .where((table) => table == DbTables.notifications)
          .listen((_) => unawaited(emitLocalNotifications()));
    };

    controller.onCancel = () async {
      await sub?.cancel();
    };

    return controller.stream;
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

    await _db.markNotificationRead(notificationId);
    _bus.notify(DbTables.notifications);
  }

  static Future<void> markAllNotificationsAsReadForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db.markAllNotificationsRead(user.uid);
    _bus.notify(DbTables.notifications);
  }

  static AppProfileData _profileFromLocalRow(
    Map<String, dynamic> row,
    User user,
  ) {
    final balanceValue = _intFromDynamic(row['balanceValue']);
    final isAdmin =
        _boolFromDynamic(row['isAdmin']) || _isAdminEmail(user.email);

    return AppProfileData(
      fullName: _nonEmpty(row['fullName']) ?? _displayNameFor(user),
      email: _nonEmpty(row['email']) ?? (user.email ?? ''),
      phoneNumber:
          _nonEmpty(row['phoneNumber']) ?? (user.phoneNumber ?? 'Not set'),
      dateOfBirth: _nonEmpty(row['dateOfBirth']) ?? 'Not set',
      nationalId: _nonEmpty(row['nationalId']) ?? 'Not set',
      address: _nonEmpty(row['address']) ?? 'Not set',
      photoUrl: _nonEmpty(row['photoUrl']) ?? _nonEmpty(user.photoURL),
      customerId: _nonEmpty(row['customerId']) ?? _customerIdFor(user),
      kycStatus: _nonEmpty(row['kycStatus']) ?? 'Pending',
      accountType: _nonEmpty(row['accountType']) ?? 'Savings Account',
      availableBalance: _formatUgx(balanceValue),
      isAdmin: isAdmin,
    );
  }

  static AppTransactionData _transactionFromLocalRow(Map<String, dynamic> row) {
    final amountValue = _intFromDynamic(row['amountValue']);
    final isCredit = _boolFromDynamic(row['isCredit']);
    final sign = isCredit ? '+' : '-';
    final createdAt = _asDateTime(row['createdAt']);
    return AppTransactionData(
      title: _nonEmpty(row['title']) ?? 'Transaction',
      subtitle: createdAt != null ? _relativeTimeLabel(createdAt) : 'Recently',
      amount: '$sign ${_formatUgx(amountValue)}',
      isCredit: isCredit,
      createdAt: createdAt,
    );
  }

  static Future<bool> isCurrentUserAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    if (_isAdminEmail(user.email)) return true;

    final userData = await _db.getUser(user.uid);
    return _boolFromDynamic(userData?['isAdmin']);
  }

  static Future<void> setUserAdminRole(String userId, bool isAdmin) async {
    await _db.updateUser(userId, {
      'isAdmin': isAdmin ? 1 : 0,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    _bus.notify(DbTables.users);
  }

  static Stream<List<AppProfileData>> watchAllUsers() {
    return _poll<List<AppProfileData>>(() async {
      final rows = await _db.getAllUsersForAdmin();
      return rows
          .map((data) {
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
    return _db.getTotalUsersCount();
  }

  static Future<int> getPendingLoansCount() async {
    return _db.getPendingLoansCount();
  }

  static Future<void> approveLoanApplication(
    String userId,
    String applicationId, {
    String? loanDocumentId,
  }) async {
    final appId = _nonEmpty(loanDocumentId) ?? applicationId;
    final app = await _loanRepository.getLoanApplication(appId);
    if (app == null) {
      throw StateError('Loan application not found');
    }

    final loanAmount = app.amountValue;
    final reviewer = FirebaseAuth.instance.currentUser?.email ?? 'admin';
    final nowIso = DateTime.now().toIso8601String();

    await _loanRepository.updateLoanApplication(
      LoanApplicationModel(
        id: app.id,
        applicationId: app.applicationId,
        userId: app.userId,
        userName: app.userName,
        userEmail: app.userEmail,
        userPhone: app.userPhone,
        customerId: app.customerId,
        loanType: app.loanType,
        amountValue: app.amountValue,
        period: app.period,
        purpose: app.purpose,
        status: DbStatus.approved,
        rejectionReason: '',
        reviewedBy: reviewer,
        reviewedAt: nowIso,
        createdAt: app.createdAt,
        updatedAt: nowIso,
        version: app.version,
        syncStatus: DbSyncStatus.pendingSync,
      ),
    );

    final currentLoan = await _loanRepository.getLatestLoan(userId);
    final loanPayload = LoanModel(
      id: currentLoan?.id ?? 'loan_$userId',
      userId: userId,
      loanId: _loanIdFor(null),
      type: app.loanType.isNotEmpty ? app.loanType : 'Loan',
      status: DbStatus.active,
      amountValue: loanAmount,
      remainingBalanceValue: loanAmount,
      period: app.period,
      purpose: app.purpose,
      nextPaymentDate: _nextPaymentDateLabel(),
      repaymentProgress: 0,
      createdAt: currentLoan?.createdAt ?? nowIso,
      updatedAt: nowIso,
      version: currentLoan?.version ?? 0,
      syncStatus: DbSyncStatus.pendingSync,
    );
    await _loanRepository.upsertLoan(loanPayload);

    final userData = await _db.getUser(userId);
    final currentBalance = _intFromDynamic(userData?['balanceValue']);
    await _db.updateUser(userId, {
      'balanceValue': currentBalance + loanAmount,
      'updatedAt': nowIso,
    });
    _bus.notify(DbTables.users);

    final accountType =
        _nonEmpty(userData?['accountType']) ?? 'Savings Account';
    await _updateAccountBalance(
      userId: userId,
      accountType: accountType,
      balanceValue: currentBalance + loanAmount,
    );

    final txId = 'tx_${DateTime.now().millisecondsSinceEpoch}';
    await _db.insertTransaction({
      'id': txId,
      'userId': userId,
      'title': 'Loan Disbursed',
      'subtitle': 'Loan approved and credited to account',
      'amountValue': loanAmount,
      'isCredit': 1,
      'createdAt': nowIso,
      'updatedAt': nowIso,
    });
    _bus.notify(DbTables.transactions);

    final accountId = await _getOrCreateAccountId(userId, accountType);
    await _loanRepository.insertLedgerEntries([
      LedgerEntryModel(
        id: 'led_loan_${appId}_cr',
        userId: userId,
        accountId: accountId,
        amountValue: loanAmount,
        entryType: DbEntryType.credit,
        referenceType: DbReferenceType.loanDisbursement,
        referenceId: appId,
        createdAt: nowIso,
        updatedAt: nowIso,
        version: 0,
        syncStatus: DbSyncStatus.pendingSync,
      ),
      LedgerEntryModel(
        id: 'led_loan_${appId}_dr',
        userId: userId,
        accountId: null,
        amountValue: loanAmount,
        entryType: DbEntryType.debit,
        referenceType: DbReferenceType.loanDisbursement,
        referenceId: appId,
        createdAt: nowIso,
        updatedAt: nowIso,
        version: 0,
        syncStatus: DbSyncStatus.pendingSync,
      ),
    ]);

    await addNotificationForUser(
      userId: userId,
      title: 'Loan Approved',
      message:
          'Your loan of ${_formatUgx(loanAmount)} has been approved and credited to your account!',
      type: 'loan',
    );
  }

  static Future<void> rejectLoanApplication(
    String userId,
    String applicationId,
    String reason, {
    String? loanDocumentId,
  }) async {
    final appId = _nonEmpty(loanDocumentId) ?? applicationId;
    final app = await _loanRepository.getLoanApplication(appId);
    if (app == null) {
      throw StateError('Loan application not found');
    }

    final reviewer = FirebaseAuth.instance.currentUser?.email ?? 'admin';
    final rejectionReason = reason.trim().isEmpty
        ? 'Please contact support for guidance.'
        : reason.trim();
    final nowIso = DateTime.now().toIso8601String();

    await _loanRepository.updateLoanApplication(
      LoanApplicationModel(
        id: app.id,
        applicationId: app.applicationId,
        userId: app.userId,
        userName: app.userName,
        userEmail: app.userEmail,
        userPhone: app.userPhone,
        customerId: app.customerId,
        loanType: app.loanType,
        amountValue: app.amountValue,
        period: app.period,
        purpose: app.purpose,
        status: DbStatus.rejected,
        rejectionReason: rejectionReason,
        reviewedBy: reviewer,
        reviewedAt: nowIso,
        createdAt: app.createdAt,
        updatedAt: nowIso,
        version: app.version,
        syncStatus: DbSyncStatus.pendingSync,
      ),
    );

    final loan = await _loanRepository.getLatestLoan(userId);
    if (loan != null) {
      await _loanRepository.upsertLoan(
        LoanModel(
          id: loan.id,
          userId: loan.userId,
          loanId: loan.loanId,
          type: loan.type,
          status: DbStatus.rejected,
          amountValue: loan.amountValue,
          remainingBalanceValue: loan.remainingBalanceValue,
          period: loan.period,
          purpose: loan.purpose,
          nextPaymentDate: 'Awaiting new application',
          repaymentProgress: loan.repaymentProgress,
          createdAt: loan.createdAt,
          updatedAt: nowIso,
          version: loan.version,
          syncStatus: DbSyncStatus.pendingSync,
        ),
      );
    }

    await addNotificationForUser(
      userId: userId,
      title: 'Loan Rejected',
      message:
          'Your loan application has been rejected. Reason: $rejectionReason',
      type: 'loan',
    );
  }

  static Future<void> repayLoan({
    required int amount,
    required String loanId,
  }) async {
    await makeLoanRepaymentForCurrentUser(
      amountValue: amount,
      method: DbDefaults.repaymentMethod,
    );
  }

  static Future<void> addNotificationForUser({
    required String userId,
    required String title,
    required String message,
    String type = 'info',
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    await _db.insertNotification({
      'id': 'notif_${DateTime.now().microsecondsSinceEpoch}',
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': 0,
      'createdAt': nowIso,
      'updatedAt': nowIso,
    });
    _bus.notify(DbTables.notifications);
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

    final loan =
        await _db.getActiveLoan(user.uid) ??
        await _db.getLatestLoanForUser(user.uid);
    if (loan == null) {
      throw StateError('No active loan found.');
    }

    final status = _nonEmpty(loan['status']) ?? 'None';
    if (status != DbStatus.active && status != DbStatus.approved) {
      throw StateError('Loan is not available for repayment.');
    }

    final amountBorrowed = _intFromDynamic(loan['amountValue']);
    final currentRemaining = _intFromDynamic(loan['remainingBalanceValue']);
    if (currentRemaining <= 0) {
      throw StateError('Loan is already fully paid.');
    }

    final amountToApply = amountValue > currentRemaining
        ? currentRemaining
        : amountValue;
    final remainingAfterPayment = currentRemaining - amountToApply;

    final safeBorrowed = amountBorrowed <= 0
        ? currentRemaining
        : amountBorrowed;
    final paidSoFar = safeBorrowed - remainingAfterPayment;
    final progress = ((paidSoFar / safeBorrowed) * 100).round().clamp(0, 100);

    final userRow = await _db.getUser(user.uid);
    final currentBalance = _intFromDynamic(userRow?['balanceValue']);
    final nextBalance = (currentBalance - amountToApply).clamp(0, 999999999);
    final nowIso = DateTime.now().toIso8601String();

    await _db.updateUser(user.uid, {
      'balanceValue': nextBalance,
      'updatedAt': nowIso,
    });
    _bus.notify(DbTables.users);

    final accountType = _nonEmpty(userRow?['accountType']) ?? 'Savings Account';
    await _updateAccountBalance(
      userId: user.uid,
      accountType: accountType,
      balanceValue: nextBalance,
    );

    await _db.updateLoan(loan['id'].toString(), {
      'remainingBalanceValue': remainingAfterPayment,
      'repaymentProgress': progress,
      'status': remainingAfterPayment <= 0 ? DbStatus.paidOff : DbStatus.active,
      'nextPaymentDate': remainingAfterPayment <= 0
          ? 'N/A'
          : _nextPaymentDateLabel(),
      'updatedAt': nowIso,
    });
    _bus.notify(DbTables.loans);

    await _db.insertTransaction({
      'id': 'tx_${DateTime.now().millisecondsSinceEpoch}',
      'userId': user.uid,
      'title': 'Loan Repayment',
      'subtitle': 'Payment via $method',
      'amountValue': amountToApply,
      'isCredit': 0,
      'createdAt': nowIso,
      'updatedAt': nowIso,
    });
    _bus.notify(DbTables.transactions);

    final accountId = await _getOrCreateAccountId(user.uid, accountType);
    await _loanRepository.insertLoanRepayment(
      LoanRepaymentModel(
        id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
        loanId: loan['id'].toString(),
        userId: user.uid,
        amountValue: amountToApply,
        method: method,
        status: DbStatus.completed,
        paidAt: nowIso,
        createdAt: nowIso,
        updatedAt: nowIso,
        version: 0,
        syncStatus: DbSyncStatus.pendingSync,
      ),
    );
    await _loanRepository.insertLedgerEntries([
      LedgerEntryModel(
        id: 'led_repay_${DateTime.now().millisecondsSinceEpoch}_dr',
        userId: user.uid,
        accountId: accountId,
        amountValue: amountToApply,
        entryType: DbEntryType.debit,
        referenceType: DbReferenceType.loanRepayment,
        referenceId: loan['id'].toString(),
        createdAt: nowIso,
        updatedAt: nowIso,
        version: 0,
        syncStatus: DbSyncStatus.pendingSync,
      ),
      LedgerEntryModel(
        id: 'led_repay_${DateTime.now().millisecondsSinceEpoch}_cr',
        userId: user.uid,
        accountId: null,
        amountValue: amountToApply,
        entryType: DbEntryType.credit,
        referenceType: DbReferenceType.loanRepayment,
        referenceId: loan['id'].toString(),
        createdAt: nowIso,
        updatedAt: nowIso,
        version: 0,
        syncStatus: DbSyncStatus.pendingSync,
      ),
    ]);

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

  static Future<String>
  getOrCreateActiveChatConversationIdForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user found.');

    final prefs = await SharedPreferences.getInstance();
    final activeKey = '$_chatActiveConversationPrefix${user.uid}';
    final existing = prefs.getString(activeKey)?.trim();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final conversationId = 'chat_${user.uid}';
    final conversations = await _loadConversations(user.uid);
    if (!conversations.any((row) => _nonEmpty(row['id']) == conversationId)) {
      conversations.add({
        'id': conversationId,
        'title': 'Current chat',
        'lastMessage': '',
        'lastMessageAt': DateTime.now().toIso8601String(),
        'unreadCount': 0,
      });
      await _saveConversations(user.uid, conversations);
    }

    await prefs.setString(activeKey, conversationId);
    return conversationId;
  }

  static Future<void> addChatMessageForCurrentUser({
    required String conversationId,
    required String text,
    required bool isUser,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user found.');

    final nowIso = DateTime.now().toIso8601String();
    final messages = await _loadMessages(user.uid);
    messages.add({
      'id': 'msg_${DateTime.now().microsecondsSinceEpoch}',
      'conversationId': conversationId,
      'isUser': isUser,
      'text': text,
      'createdAt': nowIso,
    });
    await _saveMessages(user.uid, messages);

    final conversations = await _loadConversations(user.uid);
    final index = conversations.indexWhere(
      (row) => _nonEmpty(row['id']) == conversationId,
    );
    final unread = !isUser
        ? (index >= 0
                  ? _intFromDynamic(conversations[index]['unreadCount'])
                  : 0) +
              1
        : (index >= 0
              ? _intFromDynamic(conversations[index]['unreadCount'])
              : 0);

    final updated = {
      'id': conversationId,
      'title': index >= 0
          ? (_nonEmpty(conversations[index]['title']) ?? 'Chat')
          : 'Chat',
      'lastMessage': text,
      'lastMessageAt': nowIso,
      'unreadCount': unread,
    };

    if (index >= 0) {
      conversations[index] = updated;
    } else {
      conversations.add(updated);
    }
    await _saveConversations(user.uid, conversations);
  }

  static Future<void> updateChatMessageForCurrentUser({
    required String messageId,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user found.');

    final messages = await _loadMessages(user.uid);
    final index = messages.indexWhere((m) => _nonEmpty(m['id']) == messageId);
    if (index < 0) return;

    messages[index]['text'] = text;
    await _saveMessages(user.uid, messages);
  }

  static Future<void> deleteChatMessageForCurrentUser(String messageId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user found.');

    final messages = await _loadMessages(user.uid);
    messages.removeWhere((m) => _nonEmpty(m['id']) == messageId);
    await _saveMessages(user.uid, messages);
  }

  static Future<String> startNewChatForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user found.');

    final conversationId =
        'chat_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
    final conversations = await _loadConversations(user.uid);
    conversations.insert(0, {
      'id': conversationId,
      'title': 'New chat',
      'lastMessage': '',
      'lastMessageAt': DateTime.now().toIso8601String(),
      'unreadCount': 0,
    });
    await _saveConversations(user.uid, conversations);
    await setActiveChatConversationIdForCurrentUser(conversationId);
    return conversationId;
  }

  static Future<int> deletePreviousChatConversationsForCurrentUser({
    required String keepConversationId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user found.');

    final conversations = await _loadConversations(user.uid);
    final beforeCount = conversations.length;
    conversations.removeWhere((c) => _nonEmpty(c['id']) != keepConversationId);
    await _saveConversations(user.uid, conversations);

    final messages = await _loadMessages(user.uid);
    messages.removeWhere(
      (m) => _nonEmpty(m['conversationId']) != keepConversationId,
    );
    await _saveMessages(user.uid, messages);

    return beforeCount - conversations.length;
  }

  static Future<void> setActiveChatConversationIdForCurrentUser(
    String conversationId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user found.');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_chatActiveConversationPrefix${user.uid}',
      conversationId,
    );

    final conversations = await _loadConversations(user.uid);
    final index = conversations.indexWhere(
      (c) => _nonEmpty(c['id']) == conversationId,
    );
    if (index >= 0) {
      conversations[index]['unreadCount'] = 0;
      await _saveConversations(user.uid, conversations);
    }
  }

  static Stream<String?> watchActiveChatConversationIdForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream<String?>.empty();

    return _poll<String?>(() async {
      return getOrCreateActiveChatConversationIdForCurrentUser();
    });
  }

  static Stream<List<AppChatMessageData>> watchChatMessagesForCurrentUser({
    required String conversationId,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<List<AppChatMessageData>>.value(
        const <AppChatMessageData>[],
      );
    }

    return _poll<List<AppChatMessageData>>(() async {
      final messages = await _loadMessages(user.uid);
      final filtered =
          messages
              .where((m) => _nonEmpty(m['conversationId']) == conversationId)
              .toList(growable: false)
            ..sort((a, b) {
              final da =
                  _asDateTime(a['createdAt']) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final db =
                  _asDateTime(b['createdAt']) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return da.compareTo(db);
            });

      return filtered
          .map(
            (m) => AppChatMessageData(
              id: _nonEmpty(m['id']) ?? '',
              conversationId: _nonEmpty(m['conversationId']) ?? '',
              isUser: _boolFromDynamic(m['isUser']),
              text: _nonEmpty(m['text']) ?? '',
              createdAt: _asDateTime(m['createdAt']),
            ),
          )
          .toList(growable: false);
    });
  }

  static Stream<List<AppChatConversationData>>
  watchChatConversationsForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream<List<AppChatConversationData>>.value(
        const <AppChatConversationData>[],
      );
    }

    return _poll<List<AppChatConversationData>>(() async {
      final conversations = await _loadConversations(user.uid);
      conversations.sort((a, b) {
        final da =
            _asDateTime(a['lastMessageAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final db =
            _asDateTime(b['lastMessageAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });

      return conversations
          .map(
            (c) => AppChatConversationData(
              id: _nonEmpty(c['id']) ?? '',
              title: _nonEmpty(c['title']) ?? 'Chat',
              lastMessage: _nonEmpty(c['lastMessage']) ?? '',
              lastMessageAt: _asDateTime(c['lastMessageAt']),
              unreadCount: _intFromDynamic(c['unreadCount']),
            ),
          )
          .toList(growable: false);
    });
  }

  static Future<void> updateSecuritySettingsForCurrentUser({
    required bool biometricEnabled,
    required bool twoFactorEnabled,
    required bool transactionAlerts,
    required bool loginAlerts,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user found.');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_securitySettingsPrefix${user.uid}',
      jsonEncode(<String, dynamic>{
        'biometricEnabled': biometricEnabled,
        'twoFactorEnabled': twoFactorEnabled,
        'transactionAlerts': transactionAlerts,
        'loginAlerts': loginAlerts,
      }),
    );
  }

  static Stream<AppSecuritySettingsData> watchSecuritySettingsForCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream<AppSecuritySettingsData>.empty();
    }

    return _poll<AppSecuritySettingsData>(() async {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_securitySettingsPrefix${user.uid}');
      if (raw == null || raw.trim().isEmpty) {
        return const AppSecuritySettingsData(
          biometricEnabled: false,
          twoFactorEnabled: false,
          transactionAlerts: true,
          loginAlerts: true,
        );
      }

      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) {
          return const AppSecuritySettingsData(
            biometricEnabled: false,
            twoFactorEnabled: false,
            transactionAlerts: true,
            loginAlerts: true,
          );
        }

        return AppSecuritySettingsData(
          biometricEnabled: _boolFromDynamic(decoded['biometricEnabled']),
          twoFactorEnabled: _boolFromDynamic(decoded['twoFactorEnabled']),
          transactionAlerts: _boolFromDynamic(decoded['transactionAlerts']),
          loginAlerts: _boolFromDynamic(decoded['loginAlerts']),
        );
      } catch (_) {
        return const AppSecuritySettingsData(
          biometricEnabled: false,
          twoFactorEnabled: false,
          transactionAlerts: true,
          loginAlerts: true,
        );
      }
    });
  }

  static Future<void> checkAndSendPaymentDueNotification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final loan = await _db.getLatestLoanForUser(user.uid);
      if (loan == null) return;

      final status = _nonEmpty(loan['status']) ?? '';
      if (status != DbStatus.active) return;

      final remainingBalance = _intFromDynamic(loan['remainingBalanceValue']);
      if (remainingBalance <= 0) return;

      final dueDate = _parseFlexibleDate(_nonEmpty(loan['nextPaymentDate']));
      if (dueDate == null) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final normalizedDue = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final daysUntilDue = normalizedDue.difference(today).inDays;

      if (daysUntilDue >= 0 && daysUntilDue <= 2) {
        final reminderKey =
            '${_nonEmpty(loan['loanId']) ?? 'active'}|${normalizedDue.toIso8601String()}|$daysUntilDue';
        final prefs = await SharedPreferences.getInstance();
        final prefsKey = '$_dueReminderPrefix${user.uid}';
        if (prefs.getString(prefsKey) == reminderKey) {
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

        await prefs.setString(prefsKey, reminderKey);
      }
    } catch (e) {
      developer.log(
        'Error checking payment due notification: $e',
        name: 'AppDataRepository',
      );
    }
  }

  static Future<List<Map<String, dynamic>>> _loadMessages(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_chatMessagesPrefix$userId');
    return _decodeList(raw);
  }

  static Future<void> _ensureDefaultAccountForUser(
    String userId,
    String accountType,
  ) async {
    await _getOrCreateAccountId(userId, accountType);
  }

  static Future<void> _updateAccountBalance({
    required String userId,
    required String accountType,
    required int balanceValue,
  }) async {
    await _db.runInTransaction((txn) async {
      await txn.update(
        DbTables.accounts,
        {
          DbColumns.balanceValue: balanceValue,
          DbColumns.updatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DbColumns.userId} = ? AND ${DbColumns.accountType} = ?',
        whereArgs: [userId, accountType],
      );
    });
    _bus.notify(DbTables.accounts);
  }

  static Future<String> _getOrCreateAccountId(
    String userId,
    String accountType,
  ) async {
    return _db.runInTransaction<String>((txn) async {
      final rows = await txn.query(
        DbTables.accounts,
        where: '${DbColumns.userId} = ? AND ${DbColumns.accountType} = ?',
        whereArgs: [userId, accountType],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return rows.first[DbColumns.id].toString();
      }

      final nowIso = DateTime.now().toIso8601String();
      final accountId = 'acct_$userId';
      await txn.insert(DbTables.accounts, {
        DbColumns.id: accountId,
        DbColumns.userId: userId,
        DbColumns.accountType: accountType,
        DbColumns.balanceValue: 0,
        DbColumns.status: DbDefaults.accountStatus,
        'currency': DbDefaults.currency,
        DbColumns.createdAt: nowIso,
        DbColumns.updatedAt: nowIso,
        DbColumns.isDeleted: 0,
        DbColumns.syncStatus: DbSyncStatus.pendingSync,
        DbColumns.version: 0,
      });
      _bus.notify(DbTables.accounts);
      return accountId;
    });
  }

  static Future<void> _saveMessages(
    String userId,
    List<Map<String, dynamic>> rows,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_chatMessagesPrefix$userId', jsonEncode(rows));
  }

  static Future<List<Map<String, dynamic>>> _loadConversations(
    String userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_chatConversationsPrefix$userId');
    return _decodeList(raw);
  }

  static Future<void> _saveConversations(
    String userId,
    List<Map<String, dynamic>> rows,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_chatConversationsPrefix$userId', jsonEncode(rows));
  }

  static List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return <Map<String, dynamic>>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <Map<String, dynamic>>[];
      }

      return decoded
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: true);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Stream<T> _poll<T>(Future<T> Function() loader) async* {
    yield await loader();
    yield* Stream<T>.periodic(_pollInterval).asyncMap((_) => loader());
  }

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

  static String _normalizeLoanApplicationStatus(String raw) {
    final value = raw.trim().toLowerCase();
    if (value == 'pending' || value == 'pending review')
      return 'Pending Review';
    if (value == 'approved') return 'Approved';
    if (value == 'rejected') return 'Rejected';
    if (value == 'active') return 'Active';
    if (value == 'paid off') return 'Paid Off';
    if (value == 'none') return 'None';
    return raw.trim().isEmpty ? 'Pending Review' : raw;
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
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final idxFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return 'UGX ${buffer.toString()}';
  }

  static String formatUgx(int amount) => _formatUgx(amount);

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
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static DateTime? _parseFlexibleDate(String? raw) {
    final text = raw?.trim() ?? '';
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
