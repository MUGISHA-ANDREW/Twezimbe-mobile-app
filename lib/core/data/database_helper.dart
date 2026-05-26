import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'package:twezimbeapp/core/data/db_constants.dart';

/// SQLite helper for Twezimbe data persistence.
class DatabaseHelper {
  DatabaseHelper._internal({
    sqflite.DatabaseFactory? databaseFactory,
    String? dbPath,
  }) : _databaseFactory = databaseFactory ?? sqflite.databaseFactory,
       _dbPathOverride = dbPath;

  static final DatabaseHelper _instance = DatabaseHelper._internal();

  /// Returns the app-wide singleton database helper.
  factory DatabaseHelper() => _instance;

  /// Creates a test-scoped helper with a custom database factory.
  factory DatabaseHelper.forTesting({
    required sqflite.DatabaseFactory databaseFactory,
    String? dbPath,
  }) {
    return DatabaseHelper._internal(
      databaseFactory: databaseFactory,
      dbPath: dbPath,
    );
  }

  static const int schemaVersion = 2;

  final sqflite.DatabaseFactory _databaseFactory;
  final String? _dbPathOverride;
  sqflite.Database? _database;
  sqflite.Database? _readOnlyDatabase;

  /// Returns a writable database instance.
  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDatabase(readOnly: false);
    return _database!;
  }

  /// Returns a read-only database instance.
  Future<sqflite.Database> get readOnlyDatabase async {
    if (_readOnlyDatabase != null) return _readOnlyDatabase!;
    _readOnlyDatabase = await _openDatabase(readOnly: true);
    return _readOnlyDatabase!;
  }

  /// Executes a unit of work in a transaction.
  Future<T> runInTransaction<T>(
    Future<T> Function(sqflite.Transaction txn) action,
  ) async {
    final db = await database;
    return db.transaction(action);
  }

  /// Closes any open database connections.
  Future<void> close() async {
    await _readOnlyDatabase?.close();
    await _database?.close();
    _readOnlyDatabase = null;
    _database = null;
  }

  Future<sqflite.Database> _openDatabase({required bool readOnly}) async {
    final path = await _resolvePath();
    return _databaseFactory.openDatabase(
      path,
      options: sqflite.OpenDatabaseOptions(
        version: schemaVersion,
        readOnly: readOnly,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<String> _resolvePath() async {
    if (_dbPathOverride != null) {
      return _dbPathOverride;
    }
    final dbPath = await sqflite.getDatabasesPath();
    return join(dbPath, 'twezimbe.db');
  }

  Future<void> _onConfigure(sqflite.Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(sqflite.Database db, int version) async {
    for (final statement in _schemaStatements()) {
      await db.execute(statement);
    }
  }

  Future<void> _onUpgrade(
    sqflite.Database db,
    int oldVersion,
    int newVersion,
  ) async {
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      await _runMigration(db, version);
    }
  }

  Future<void> _runMigration(sqflite.Database db, int version) async {
    switch (version) {
      case 1:
        for (final statement in _schemaStatements()) {
          await db.execute(statement);
        }
        break;
      case 2:
        await _dropAllTables(db);
        for (final statement in _schemaStatements()) {
          await db.execute(statement);
        }
        break;
      default:
        break;
    }
  }

  List<String> _schemaStatements() {
    return <String>[
      '''
      CREATE TABLE ${DbTables.users} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        ${DbColumns.fullName} TEXT,
        ${DbColumns.email} TEXT,
        ${DbColumns.phoneNumber} TEXT,
        ${DbColumns.dateOfBirth} TEXT,
        ${DbColumns.nationalId} TEXT,
        ${DbColumns.address} TEXT,
        ${DbColumns.photoUrl} TEXT,
        ${DbColumns.customerId} TEXT,
        ${DbColumns.kycStatus} TEXT,
        ${DbColumns.accountType} TEXT,
        ${DbColumns.balanceValue} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.balanceValue} >= 0),
        ${DbColumns.isAdmin} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.isAdmin} IN (0, 1)),
        ${DbColumns.fcmToken} TEXT,
        ${DbColumns.createdAt} TEXT NOT NULL,
        ${DbColumns.updatedAt} TEXT NOT NULL,
        ${DbColumns.isDeleted} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.isDeleted} IN (0, 1)),
        ${DbColumns.syncStatus} TEXT NOT NULL DEFAULT '${DbSyncStatus.synced}' CHECK (${DbColumns.syncStatus} IN ('${DbSyncStatus.synced}', '${DbSyncStatus.pendingSync}', '${DbSyncStatus.conflict}')),
        ${DbColumns.version} INTEGER NOT NULL DEFAULT 0
      )
      ''',
      '''
      CREATE TABLE ${DbTables.accounts} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        ${DbColumns.userId} TEXT NOT NULL,
        ${DbColumns.accountType} TEXT NOT NULL,
        ${DbColumns.balanceValue} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.balanceValue} >= 0),
        ${DbColumns.status} TEXT NOT NULL,
        currency TEXT NOT NULL DEFAULT '${DbDefaults.currency}',
        ${DbColumns.createdAt} TEXT NOT NULL,
        ${DbColumns.updatedAt} TEXT NOT NULL,
        ${DbColumns.isDeleted} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.isDeleted} IN (0, 1)),
        ${DbColumns.syncStatus} TEXT NOT NULL DEFAULT '${DbSyncStatus.synced}' CHECK (${DbColumns.syncStatus} IN ('${DbSyncStatus.synced}', '${DbSyncStatus.pendingSync}', '${DbSyncStatus.conflict}')),
        ${DbColumns.version} INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (${DbColumns.userId}) REFERENCES ${DbTables.users}(${DbColumns.id})
      )
      ''',
      '''
      CREATE TABLE ${DbTables.loans} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        ${DbColumns.userId} TEXT NOT NULL,
        ${DbColumns.accountId} TEXT,
        ${DbColumns.loanId} TEXT,
        loan_type TEXT,
        ${DbColumns.status} TEXT NOT NULL CHECK (${DbColumns.status} IN ('${DbStatus.pending}', '${DbStatus.approved}', '${DbStatus.active}', '${DbStatus.rejected}', '${DbStatus.paidOff}', '${DbStatus.completed}', '${DbStatus.none}')),
        ${DbColumns.amountValue} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.amountValue} >= 0),
        ${DbColumns.remainingBalanceValue} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.remainingBalanceValue} >= 0),
        ${DbColumns.interestRateBps} INTEGER NOT NULL DEFAULT 0,
        ${DbColumns.period} TEXT,
        ${DbColumns.purpose} TEXT,
        ${DbColumns.nextPaymentDate} TEXT,
        ${DbColumns.repaymentProgress} INTEGER NOT NULL DEFAULT 0,
        ${DbColumns.createdAt} TEXT NOT NULL,
        ${DbColumns.updatedAt} TEXT NOT NULL,
        ${DbColumns.isDeleted} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.isDeleted} IN (0, 1)),
        ${DbColumns.syncStatus} TEXT NOT NULL DEFAULT '${DbSyncStatus.synced}' CHECK (${DbColumns.syncStatus} IN ('${DbSyncStatus.synced}', '${DbSyncStatus.pendingSync}', '${DbSyncStatus.conflict}')),
        ${DbColumns.version} INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (${DbColumns.userId}) REFERENCES ${DbTables.users}(${DbColumns.id}),
        FOREIGN KEY (${DbColumns.accountId}) REFERENCES ${DbTables.accounts}(${DbColumns.id})
      )
      ''',
      '''
      CREATE TABLE ${DbTables.loanRepayments} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        ${DbColumns.loanId} TEXT NOT NULL,
        ${DbColumns.userId} TEXT NOT NULL,
        ${DbColumns.amountValue} INTEGER NOT NULL CHECK (${DbColumns.amountValue} > 0),
        ${DbColumns.method} TEXT,
        ${DbColumns.status} TEXT NOT NULL CHECK (${DbColumns.status} IN ('${DbStatus.pending}', '${DbStatus.completed}', '${DbStatus.failed}')),
        paid_at TEXT,
        ${DbColumns.createdAt} TEXT NOT NULL,
        ${DbColumns.updatedAt} TEXT NOT NULL,
        ${DbColumns.isDeleted} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.isDeleted} IN (0, 1)),
        ${DbColumns.syncStatus} TEXT NOT NULL DEFAULT '${DbSyncStatus.synced}' CHECK (${DbColumns.syncStatus} IN ('${DbSyncStatus.synced}', '${DbSyncStatus.pendingSync}', '${DbSyncStatus.conflict}')),
        ${DbColumns.version} INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (${DbColumns.loanId}) REFERENCES ${DbTables.loans}(${DbColumns.id}),
        FOREIGN KEY (${DbColumns.userId}) REFERENCES ${DbTables.users}(${DbColumns.id})
      )
      ''',
      '''
      CREATE TABLE ${DbTables.loanApplications} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        ${DbColumns.applicationId} TEXT,
        ${DbColumns.userId} TEXT NOT NULL,
        user_name TEXT,
        user_email TEXT,
        user_phone TEXT,
        ${DbColumns.customerId} TEXT,
        loan_type TEXT,
        ${DbColumns.amountValue} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.amountValue} >= 0),
        ${DbColumns.period} TEXT,
        ${DbColumns.purpose} TEXT,
        ${DbColumns.status} TEXT NOT NULL CHECK (${DbColumns.status} IN ('${DbStatus.pending}', '${DbStatus.approved}', '${DbStatus.rejected}', '${DbStatus.active}', '${DbStatus.completed}', '${DbStatus.paidOff}', '${DbStatus.none}')),
        ${DbColumns.rejectionReason} TEXT,
        ${DbColumns.reviewedBy} TEXT,
        ${DbColumns.reviewedAt} TEXT,
        ${DbColumns.createdAt} TEXT NOT NULL,
        ${DbColumns.updatedAt} TEXT NOT NULL,
        ${DbColumns.isDeleted} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.isDeleted} IN (0, 1)),
        ${DbColumns.syncStatus} TEXT NOT NULL DEFAULT '${DbSyncStatus.synced}' CHECK (${DbColumns.syncStatus} IN ('${DbSyncStatus.synced}', '${DbSyncStatus.pendingSync}', '${DbSyncStatus.conflict}')),
        ${DbColumns.version} INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (${DbColumns.userId}) REFERENCES ${DbTables.users}(${DbColumns.id})
      )
      ''',
      '''
      CREATE TABLE ${DbTables.deposits} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        ${DbColumns.userId} TEXT NOT NULL,
        ${DbColumns.accountId} TEXT,
        ${DbColumns.amountValue} INTEGER NOT NULL CHECK (${DbColumns.amountValue} > 0),
        ${DbColumns.method} TEXT,
        ${DbColumns.status} TEXT NOT NULL CHECK (${DbColumns.status} IN ('${DbStatus.pending}', '${DbStatus.completed}', '${DbStatus.failed}')),
        ${DbColumns.reference} TEXT,
        ${DbColumns.createdAt} TEXT NOT NULL,
        ${DbColumns.updatedAt} TEXT NOT NULL,
        ${DbColumns.isDeleted} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.isDeleted} IN (0, 1)),
        ${DbColumns.syncStatus} TEXT NOT NULL DEFAULT '${DbSyncStatus.synced}' CHECK (${DbColumns.syncStatus} IN ('${DbSyncStatus.synced}', '${DbSyncStatus.pendingSync}', '${DbSyncStatus.conflict}')),
        ${DbColumns.version} INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (${DbColumns.userId}) REFERENCES ${DbTables.users}(${DbColumns.id}),
        FOREIGN KEY (${DbColumns.accountId}) REFERENCES ${DbTables.accounts}(${DbColumns.id})
      )
      ''',
      '''
      CREATE TABLE ${DbTables.depositTransactions} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        ${DbColumns.depositId} TEXT NOT NULL,
        ${DbColumns.userId} TEXT NOT NULL,
        ${DbColumns.amountValue} INTEGER NOT NULL CHECK (${DbColumns.amountValue} > 0),
        ${DbColumns.entryType} TEXT NOT NULL CHECK (${DbColumns.entryType} IN ('${DbEntryType.credit}', '${DbEntryType.debit}')),
        ${DbColumns.createdAt} TEXT NOT NULL,
        ${DbColumns.updatedAt} TEXT NOT NULL,
        ${DbColumns.isDeleted} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.isDeleted} IN (0, 1)),
        ${DbColumns.syncStatus} TEXT NOT NULL DEFAULT '${DbSyncStatus.synced}' CHECK (${DbColumns.syncStatus} IN ('${DbSyncStatus.synced}', '${DbSyncStatus.pendingSync}', '${DbSyncStatus.conflict}')),
        ${DbColumns.version} INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (${DbColumns.depositId}) REFERENCES ${DbTables.deposits}(${DbColumns.id}),
        FOREIGN KEY (${DbColumns.userId}) REFERENCES ${DbTables.users}(${DbColumns.id})
      )
      ''',
      '''
      CREATE TABLE ${DbTables.withdrawals} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        ${DbColumns.userId} TEXT NOT NULL,
        ${DbColumns.accountId} TEXT,
        ${DbColumns.amountValue} INTEGER NOT NULL CHECK (${DbColumns.amountValue} > 0),
        ${DbColumns.method} TEXT,
        ${DbColumns.status} TEXT NOT NULL CHECK (${DbColumns.status} IN ('${DbStatus.pending}', '${DbStatus.approved}', '${DbStatus.rejected}', '${DbStatus.completed}')),
        requested_at TEXT,
        processed_at TEXT,
        ${DbColumns.reference} TEXT,
        ${DbColumns.createdAt} TEXT NOT NULL,
        ${DbColumns.updatedAt} TEXT NOT NULL,
        ${DbColumns.isDeleted} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.isDeleted} IN (0, 1)),
        ${DbColumns.syncStatus} TEXT NOT NULL DEFAULT '${DbSyncStatus.synced}' CHECK (${DbColumns.syncStatus} IN ('${DbSyncStatus.synced}', '${DbSyncStatus.pendingSync}', '${DbSyncStatus.conflict}')),
        ${DbColumns.version} INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (${DbColumns.userId}) REFERENCES ${DbTables.users}(${DbColumns.id}),
        FOREIGN KEY (${DbColumns.accountId}) REFERENCES ${DbTables.accounts}(${DbColumns.id})
      )
      ''',
      '''
      CREATE TABLE ${DbTables.ledgerEntries} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        ${DbColumns.userId} TEXT NOT NULL,
        ${DbColumns.accountId} TEXT,
        ${DbColumns.amountValue} INTEGER NOT NULL CHECK (${DbColumns.amountValue} > 0),
        ${DbColumns.entryType} TEXT NOT NULL CHECK (${DbColumns.entryType} IN ('${DbEntryType.debit}', '${DbEntryType.credit}')),
        ${DbColumns.referenceType} TEXT NOT NULL,
        ${DbColumns.referenceId} TEXT NOT NULL,
        ${DbColumns.createdAt} TEXT NOT NULL,
        ${DbColumns.updatedAt} TEXT NOT NULL,
        ${DbColumns.isDeleted} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.isDeleted} IN (0, 1)),
        ${DbColumns.syncStatus} TEXT NOT NULL DEFAULT '${DbSyncStatus.synced}' CHECK (${DbColumns.syncStatus} IN ('${DbSyncStatus.synced}', '${DbSyncStatus.pendingSync}', '${DbSyncStatus.conflict}')),
        ${DbColumns.version} INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (${DbColumns.userId}) REFERENCES ${DbTables.users}(${DbColumns.id}),
        FOREIGN KEY (${DbColumns.accountId}) REFERENCES ${DbTables.accounts}(${DbColumns.id})
      )
      ''',
      '''
      CREATE TABLE ${DbTables.transactions} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        ${DbColumns.userId} TEXT NOT NULL,
        ${DbColumns.title} TEXT,
        ${DbColumns.subtitle} TEXT,
        ${DbColumns.amountValue} INTEGER NOT NULL CHECK (${DbColumns.amountValue} >= 0),
        ${DbColumns.isCredit} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.isCredit} IN (0, 1)),
        ${DbColumns.createdAt} TEXT NOT NULL,
        ${DbColumns.updatedAt} TEXT NOT NULL,
        ${DbColumns.isDeleted} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.isDeleted} IN (0, 1)),
        ${DbColumns.syncStatus} TEXT NOT NULL DEFAULT '${DbSyncStatus.synced}' CHECK (${DbColumns.syncStatus} IN ('${DbSyncStatus.synced}', '${DbSyncStatus.pendingSync}', '${DbSyncStatus.conflict}')),
        ${DbColumns.version} INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (${DbColumns.userId}) REFERENCES ${DbTables.users}(${DbColumns.id})
      )
      ''',
      '''
      CREATE TABLE ${DbTables.notifications} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        ${DbColumns.userId} TEXT NOT NULL,
        ${DbColumns.title} TEXT,
        ${DbColumns.message} TEXT,
        ${DbColumns.type} TEXT,
        ${DbColumns.isRead} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.isRead} IN (0, 1)),
        ${DbColumns.createdAt} TEXT NOT NULL,
        ${DbColumns.updatedAt} TEXT NOT NULL,
        ${DbColumns.isDeleted} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.isDeleted} IN (0, 1)),
        ${DbColumns.syncStatus} TEXT NOT NULL DEFAULT '${DbSyncStatus.synced}' CHECK (${DbColumns.syncStatus} IN ('${DbSyncStatus.synced}', '${DbSyncStatus.pendingSync}', '${DbSyncStatus.conflict}')),
        ${DbColumns.version} INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (${DbColumns.userId}) REFERENCES ${DbTables.users}(${DbColumns.id})
      )
      ''',
      '''
      CREATE TABLE ${DbTables.adminRequests} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        request_id TEXT,
        ${DbColumns.type} TEXT,
        ${DbColumns.userId} TEXT,
        user_name TEXT,
        user_email TEXT,
        ${DbColumns.status} TEXT,
        ${DbColumns.createdAt} TEXT NOT NULL,
        ${DbColumns.updatedAt} TEXT NOT NULL,
        ${DbColumns.isDeleted} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.isDeleted} IN (0, 1)),
        ${DbColumns.syncStatus} TEXT NOT NULL DEFAULT '${DbSyncStatus.synced}' CHECK (${DbColumns.syncStatus} IN ('${DbSyncStatus.synced}', '${DbSyncStatus.pendingSync}', '${DbSyncStatus.conflict}')),
        ${DbColumns.version} INTEGER NOT NULL DEFAULT 0
      )
      ''',
      '''
      CREATE TABLE ${DbTables.pendingSyncQueue} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        ${DbColumns.operation} TEXT NOT NULL CHECK (${DbColumns.operation} IN ('${DbOperations.insert}', '${DbOperations.update}', '${DbOperations.delete}')),
        ${DbColumns.payloadJson} TEXT NOT NULL,
        ${DbColumns.createdAt} TEXT NOT NULL
      )
      ''',
      '''
      CREATE TABLE ${DbTables.loanProducts} (
        ${DbColumns.id} TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        ${DbColumns.interestRateBps} INTEGER NOT NULL DEFAULT 0,
        min_amount_value INTEGER NOT NULL DEFAULT 0,
        max_amount_value INTEGER NOT NULL DEFAULT 0,
        ${DbColumns.createdAt} TEXT NOT NULL,
        ${DbColumns.updatedAt} TEXT NOT NULL,
        ${DbColumns.isDeleted} INTEGER NOT NULL DEFAULT 0 CHECK (${DbColumns.isDeleted} IN (0, 1)),
        ${DbColumns.syncStatus} TEXT NOT NULL DEFAULT '${DbSyncStatus.synced}' CHECK (${DbColumns.syncStatus} IN ('${DbSyncStatus.synced}', '${DbSyncStatus.pendingSync}', '${DbSyncStatus.conflict}')),
        ${DbColumns.version} INTEGER NOT NULL DEFAULT 0
      )
      ''',
      'CREATE INDEX idx_users_email ON ${DbTables.users}(${DbColumns.email})',
      'CREATE INDEX idx_accounts_user ON ${DbTables.accounts}(${DbColumns.userId})',
      'CREATE INDEX idx_loans_user_status ON ${DbTables.loans}(${DbColumns.userId}, ${DbColumns.status})',
      'CREATE INDEX idx_loans_user_created ON ${DbTables.loans}(${DbColumns.userId}, ${DbColumns.createdAt} DESC)',
      'CREATE INDEX idx_loan_app_user_status ON ${DbTables.loanApplications}(${DbColumns.userId}, ${DbColumns.status})',
      'CREATE INDEX idx_loan_app_user_created ON ${DbTables.loanApplications}(${DbColumns.userId}, ${DbColumns.createdAt} DESC)',
      'CREATE INDEX idx_loan_rep_loan ON ${DbTables.loanRepayments}(${DbColumns.loanId})',
      'CREATE INDEX idx_deposits_user_status ON ${DbTables.deposits}(${DbColumns.userId}, ${DbColumns.status})',
      'CREATE INDEX idx_deposits_user_created ON ${DbTables.deposits}(${DbColumns.userId}, ${DbColumns.createdAt} DESC)',
      'CREATE INDEX idx_withdrawals_user_status ON ${DbTables.withdrawals}(${DbColumns.userId}, ${DbColumns.status})',
      'CREATE INDEX idx_withdrawals_user_created ON ${DbTables.withdrawals}(${DbColumns.userId}, ${DbColumns.createdAt} DESC)',
      'CREATE INDEX idx_transactions_user_created ON ${DbTables.transactions}(${DbColumns.userId}, ${DbColumns.createdAt} DESC)',
      'CREATE INDEX idx_notifications_user_created ON ${DbTables.notifications}(${DbColumns.userId}, ${DbColumns.createdAt} DESC)',
      'CREATE INDEX idx_ledger_user_created ON ${DbTables.ledgerEntries}(${DbColumns.userId}, ${DbColumns.createdAt} DESC)',
    ];
  }

  Future<void> _dropAllTables(sqflite.Database db) async {
    const tables = <String>[
      DbTables.loanProducts,
      DbTables.pendingSyncQueue,
      DbTables.adminRequests,
      DbTables.notifications,
      DbTables.transactions,
      DbTables.ledgerEntries,
      DbTables.withdrawals,
      DbTables.depositTransactions,
      DbTables.deposits,
      DbTables.loanApplications,
      DbTables.loanRepayments,
      DbTables.loans,
      DbTables.accounts,
      DbTables.users,
    ];

    for (final table in tables) {
      await db.execute('DROP TABLE IF EXISTS $table');
    }
  }

  Map<String, dynamic> _toDb(
    Map<String, dynamic> data,
    Map<String, String> mapping,
  ) {
    final mapped = <String, dynamic>{};
    for (final entry in data.entries) {
      final key = mapping[entry.key] ?? entry.key;
      mapped[key] = entry.value;
    }
    return mapped;
  }

  Map<String, dynamic> _fromDb(
    Map<String, dynamic> row,
    Map<String, String> mapping,
  ) {
    final mapped = <String, dynamic>{};
    for (final entry in mapping.entries) {
      if (row.containsKey(entry.value)) {
        mapped[entry.key] = row[entry.value];
      }
    }
    return mapped;
  }

  static const Map<String, String> _userMap = {
    'id': DbColumns.id,
    'fullName': DbColumns.fullName,
    'email': DbColumns.email,
    'phoneNumber': DbColumns.phoneNumber,
    'dateOfBirth': DbColumns.dateOfBirth,
    'nationalId': DbColumns.nationalId,
    'address': DbColumns.address,
    'photoUrl': DbColumns.photoUrl,
    'customerId': DbColumns.customerId,
    'kycStatus': DbColumns.kycStatus,
    'accountType': DbColumns.accountType,
    'balanceValue': DbColumns.balanceValue,
    'isAdmin': DbColumns.isAdmin,
    'fcmToken': DbColumns.fcmToken,
    'createdAt': DbColumns.createdAt,
    'updatedAt': DbColumns.updatedAt,
    'isDeleted': DbColumns.isDeleted,
    'syncStatus': DbColumns.syncStatus,
    'version': DbColumns.version,
  };

  static const Map<String, String> _loanMap = {
    'id': DbColumns.id,
    'userId': DbColumns.userId,
    'loanId': DbColumns.loanId,
    'type': 'loan_type',
    'status': DbColumns.status,
    'amountValue': DbColumns.amountValue,
    'remainingBalanceValue': DbColumns.remainingBalanceValue,
    'period': DbColumns.period,
    'purpose': DbColumns.purpose,
    'nextPaymentDate': DbColumns.nextPaymentDate,
    'repaymentProgress': DbColumns.repaymentProgress,
    'createdAt': DbColumns.createdAt,
    'updatedAt': DbColumns.updatedAt,
    'syncStatus': DbColumns.syncStatus,
    'version': DbColumns.version,
  };

  static const Map<String, String> _loanApplicationMap = {
    'id': DbColumns.id,
    'applicationId': DbColumns.applicationId,
    'userId': DbColumns.userId,
    'userName': 'user_name',
    'userEmail': 'user_email',
    'userPhone': 'user_phone',
    'customerId': DbColumns.customerId,
    'loanType': 'loan_type',
    'amountValue': DbColumns.amountValue,
    'period': DbColumns.period,
    'purpose': DbColumns.purpose,
    'status': DbColumns.status,
    'rejectionReason': DbColumns.rejectionReason,
    'reviewedBy': DbColumns.reviewedBy,
    'reviewedAt': DbColumns.reviewedAt,
    'createdAt': DbColumns.createdAt,
    'updatedAt': DbColumns.updatedAt,
    'syncStatus': DbColumns.syncStatus,
    'version': DbColumns.version,
  };

  static const Map<String, String> _transactionMap = {
    'id': DbColumns.id,
    'userId': DbColumns.userId,
    'title': DbColumns.title,
    'subtitle': DbColumns.subtitle,
    'amountValue': DbColumns.amountValue,
    'isCredit': DbColumns.isCredit,
    'createdAt': DbColumns.createdAt,
    'updatedAt': DbColumns.updatedAt,
  };

  static const Map<String, String> _notificationMap = {
    'id': DbColumns.id,
    'userId': DbColumns.userId,
    'title': DbColumns.title,
    'message': DbColumns.message,
    'type': DbColumns.type,
    'isRead': DbColumns.isRead,
    'createdAt': DbColumns.createdAt,
    'updatedAt': DbColumns.updatedAt,
  };

  Future<int> insertUser(Map<String, dynamic> user) async {
    final data = _toDb(user, _userMap);
    return runInTransaction<int>((txn) async {
      return txn.insert(
        DbTables.users,
        data,
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> upsertUsers(List<Map<String, dynamic>> users) async {
    if (users.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final user in users) {
        batch.insert(
          DbTables.users,
          _toDb(user, _userMap),
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    final db = await readOnlyDatabase;
    final results = await db.query(
      DbTables.users,
      where: '${DbColumns.id} = ?',
      whereArgs: [userId],
    );
    if (results.isEmpty) return null;
    return _fromDb(results.first, _userMap);
  }

  Future<int> updateUser(String userId, Map<String, dynamic> user) async {
    return runInTransaction<int>((txn) async {
      return txn.update(
        DbTables.users,
        _toDb(user, _userMap),
        where: '${DbColumns.id} = ?',
        whereArgs: [userId],
      );
    });
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await readOnlyDatabase;
    final results = await db.query(
      DbTables.users,
      orderBy: '${DbColumns.createdAt} DESC',
    );
    return results.map((row) => _fromDb(row, _userMap)).toList();
  }

  Future<int> deleteUser(String userId) async {
    return runInTransaction<int>((txn) async {
      return txn.delete(
        DbTables.users,
        where: '${DbColumns.id} = ?',
        whereArgs: [userId],
      );
    });
  }

  Future<void> deleteUserRelatedData(String userId) async {
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      batch.delete(
        DbTables.loanApplications,
        where: '${DbColumns.userId} = ?',
        whereArgs: [userId],
      );
      batch.delete(
        DbTables.loans,
        where: '${DbColumns.userId} = ?',
        whereArgs: [userId],
      );
      batch.delete(
        DbTables.transactions,
        where: '${DbColumns.userId} = ?',
        whereArgs: [userId],
      );
      batch.delete(
        DbTables.notifications,
        where: '${DbColumns.userId} = ?',
        whereArgs: [userId],
      );
      batch.delete(
        DbTables.adminRequests,
        where: '${DbColumns.userId} = ?',
        whereArgs: [userId],
      );
      batch.delete(
        DbTables.users,
        where: '${DbColumns.id} = ?',
        whereArgs: [userId],
      );
      await batch.commit(noResult: true);
    });
  }

  Future<int> insertLoan(Map<String, dynamic> loan) async {
    return runInTransaction<int>((txn) async {
      return txn.insert(
        DbTables.loans,
        _toDb(loan, _loanMap),
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    });
  }

  Future<Map<String, dynamic>?> getActiveLoan(String userId) async {
    final db = await readOnlyDatabase;
    final results = await db.query(
      DbTables.loans,
      where: '${DbColumns.userId} = ? AND ${DbColumns.status} = ?',
      whereArgs: [userId, DbStatus.active],
      orderBy: '${DbColumns.updatedAt} DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return _fromDb(results.first, _loanMap);
  }

  Future<Map<String, dynamic>?> getLatestLoanForUser(String userId) async {
    final db = await readOnlyDatabase;
    final results = await db.query(
      DbTables.loans,
      where: '${DbColumns.userId} = ?',
      whereArgs: [userId],
      orderBy: '${DbColumns.updatedAt} DESC, ${DbColumns.createdAt} DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return _fromDb(results.first, _loanMap);
  }

  Future<int> updateLoan(String loanId, Map<String, dynamic> loan) async {
    return runInTransaction<int>((txn) async {
      return txn.update(
        DbTables.loans,
        _toDb(loan, _loanMap),
        where: '${DbColumns.id} = ?',
        whereArgs: [loanId],
      );
    });
  }

  Future<int> insertLoanApplication(Map<String, dynamic> app) async {
    return runInTransaction<int>((txn) async {
      return txn.insert(
        DbTables.loanApplications,
        _toDb(app, _loanApplicationMap),
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> upsertLoanApplications(List<Map<String, dynamic>> apps) async {
    if (apps.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final app in apps) {
        batch.insert(
          DbTables.loanApplications,
          _toDb(app, _loanApplicationMap),
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Map<String, dynamic>>> getLoanApplications(String userId) async {
    final db = await readOnlyDatabase;
    final results = await db.query(
      DbTables.loanApplications,
      where: '${DbColumns.userId} = ?',
      whereArgs: [userId],
      orderBy: '${DbColumns.createdAt} DESC',
    );
    return results.map((row) => _fromDb(row, _loanApplicationMap)).toList();
  }

  Future<List<Map<String, dynamic>>> getLoanApplicationsPaged(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await readOnlyDatabase;
    final results = await db.query(
      DbTables.loanApplications,
      where: '${DbColumns.userId} = ?',
      whereArgs: [userId],
      orderBy: '${DbColumns.createdAt} DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => _fromDb(row, _loanApplicationMap)).toList();
  }

  Future<List<Map<String, dynamic>>> getAllLoanApplications() async {
    final db = await readOnlyDatabase;
    final results = await db.query(
      DbTables.loanApplications,
      orderBy: '${DbColumns.createdAt} DESC',
    );
    return results.map((row) => _fromDb(row, _loanApplicationMap)).toList();
  }

  Future<Map<String, dynamic>?> getLoanApplication(String applicationId) async {
    final lookupId = applicationId.trim();
    if (lookupId.isEmpty) return null;

    final db = await readOnlyDatabase;
    final results = await db.query(
      DbTables.loanApplications,
      where: '(${DbColumns.applicationId} = ? OR ${DbColumns.id} = ?)',
      whereArgs: [lookupId, lookupId],
    );
    if (results.isEmpty) return null;
    return _fromDb(results.first, _loanApplicationMap);
  }

  Future<int> updateLoanApplication(
    String applicationId,
    Map<String, dynamic> app,
  ) async {
    final lookupId = applicationId.trim();
    if (lookupId.isEmpty) return 0;

    return runInTransaction<int>((txn) async {
      return txn.update(
        DbTables.loanApplications,
        _toDb(app, _loanApplicationMap),
        where: '(${DbColumns.applicationId} = ? OR ${DbColumns.id} = ?)',
        whereArgs: [lookupId, lookupId],
      );
    });
  }

  Future<int> insertTransaction(Map<String, dynamic> tx) async {
    return runInTransaction<int>((txn) async {
      return txn.insert(DbTables.transactions, _toDb(tx, _transactionMap));
    });
  }

  Future<void> upsertTransactions(
    List<Map<String, dynamic>> transactions,
  ) async {
    if (transactions.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final tx in transactions) {
        batch.insert(
          DbTables.transactions,
          _toDb(tx, _transactionMap),
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Map<String, dynamic>>> getTransactions(
    String userId, {
    int limit = 100,
  }) async {
    final db = await readOnlyDatabase;
    final results = await db.query(
      DbTables.transactions,
      where: '${DbColumns.userId} = ?',
      whereArgs: [userId],
      orderBy: '${DbColumns.createdAt} DESC',
      limit: limit,
    );
    return results.map((row) => _fromDb(row, _transactionMap)).toList();
  }

  Future<List<Map<String, dynamic>>> getTransactionsPaged(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await readOnlyDatabase;
    final results = await db.query(
      DbTables.transactions,
      where: '${DbColumns.userId} = ?',
      whereArgs: [userId],
      orderBy: '${DbColumns.createdAt} DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => _fromDb(row, _transactionMap)).toList();
  }

  Future<int> insertNotification(Map<String, dynamic> notif) async {
    return runInTransaction<int>((txn) async {
      return txn.insert(DbTables.notifications, _toDb(notif, _notificationMap));
    });
  }

  Future<void> upsertNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    if (notifications.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final notif in notifications) {
        batch.insert(
          DbTables.notifications,
          _toDb(notif, _notificationMap),
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Map<String, dynamic>>> getNotifications(
    String userId, {
    int limit = 100,
  }) async {
    final db = await readOnlyDatabase;
    final results = await db.query(
      DbTables.notifications,
      where: '${DbColumns.userId} = ?',
      whereArgs: [userId],
      orderBy: '${DbColumns.createdAt} DESC',
      limit: limit,
    );
    return results.map((row) => _fromDb(row, _notificationMap)).toList();
  }

  Future<List<Map<String, dynamic>>> getNotificationsPaged(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await readOnlyDatabase;
    final results = await db.query(
      DbTables.notifications,
      where: '${DbColumns.userId} = ?',
      whereArgs: [userId],
      orderBy: '${DbColumns.createdAt} DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => _fromDb(row, _notificationMap)).toList();
  }

  Future<int> markNotificationRead(String notifId) async {
    return runInTransaction<int>((txn) async {
      return txn.update(
        DbTables.notifications,
        {
          DbColumns.isRead: 1,
          DbColumns.updatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DbColumns.id} = ?',
        whereArgs: [notifId],
      );
    });
  }

  Future<int> markAllNotificationsRead(String userId) async {
    return runInTransaction<int>((txn) async {
      return txn.update(
        DbTables.notifications,
        {
          DbColumns.isRead: 1,
          DbColumns.updatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DbColumns.userId} = ? AND ${DbColumns.isRead} = 0',
        whereArgs: [userId],
      );
    });
  }

  Future<int> insertAdminRequest(Map<String, dynamic> req) async {
    return runInTransaction<int>((txn) async {
      return txn.insert(
        DbTables.adminRequests,
        req,
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    });
  }

  Future<List<Map<String, dynamic>>> getAllAdminRequests() async {
    final db = await readOnlyDatabase;
    return db.query(
      DbTables.adminRequests,
      orderBy: '${DbColumns.createdAt} DESC',
    );
  }

  Future<int> updateAdminRequest(
    String requestId,
    Map<String, dynamic> req,
  ) async {
    return runInTransaction<int>((txn) async {
      return txn.update(
        DbTables.adminRequests,
        req,
        where: 'request_id = ?',
        whereArgs: [requestId],
      );
    });
  }

  Future<List<Map<String, dynamic>>> getAllUsersForAdmin() async {
    final db = await readOnlyDatabase;
    final results = await db.query(
      DbTables.users,
      orderBy: '${DbColumns.createdAt} DESC',
    );
    return results.map((row) => _fromDb(row, _userMap)).toList();
  }

  Future<int> getPendingLoansCount() async {
    final db = await readOnlyDatabase;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM ${DbTables.loanApplications} WHERE ${DbColumns.status} = ?",
      [DbStatus.pending],
    );
    return sqflite.Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getActiveLoansCount() async {
    final db = await readOnlyDatabase;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM ${DbTables.loanApplications} WHERE ${DbColumns.status} IN (?, ?)",
      [DbStatus.approved, DbStatus.active],
    );
    return sqflite.Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getAllLoansForAdmin() async {
    final db = await readOnlyDatabase;
    final results = await db.query(
      DbTables.loans,
      orderBy: '${DbColumns.updatedAt} DESC, ${DbColumns.createdAt} DESC',
    );
    return results.map((row) => _fromDb(row, _loanMap)).toList();
  }

  Future<int> getTotalUserBalances() async {
    final db = await readOnlyDatabase;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(${DbColumns.balanceValue}), 0) as total FROM ${DbTables.users}',
    );
    return sqflite.Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalIncomeFromTransactions() async {
    final db = await readOnlyDatabase;
    // EXPLAIN QUERY PLAN: uses idx_transactions_user_created for ordering.
    final result = await db.rawQuery('''
      SELECT COALESCE(
        SUM(
          CASE
            WHEN ${DbColumns.isCredit} = 1 OR LOWER(${DbColumns.title}) LIKE '%repayment%'
            THEN ${DbColumns.amountValue}
            ELSE 0
          END
        ),
        0
      ) as total
      FROM ${DbTables.transactions}
    ''');
    return sqflite.Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getRecentUsersForAdmin({
    int limit = 5,
  }) async {
    final db = await readOnlyDatabase;
    final results = await db.query(
      DbTables.users,
      orderBy: '${DbColumns.createdAt} DESC',
      limit: limit,
    );
    return results.map((row) => _fromDb(row, _userMap)).toList();
  }

  Future<int> getTotalUsersCount() async {
    final db = await readOnlyDatabase;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DbTables.users}',
    );
    return sqflite.Sqflite.firstIntValue(result) ?? 0;
  }
}
