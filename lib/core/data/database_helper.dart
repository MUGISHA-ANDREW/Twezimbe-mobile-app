import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'twezimbe.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        fullName TEXT,
        email TEXT,
        phoneNumber TEXT,
        dateOfBirth TEXT,
        nationalId TEXT,
        address TEXT,
        photoUrl TEXT,
        customerId TEXT,
        kycStatus TEXT DEFAULT 'Pending',
        accountType TEXT DEFAULT 'Savings Account',
        balanceValue INTEGER DEFAULT 0,
        isAdmin INTEGER DEFAULT 0,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');

    // Loans table
    await db.execute('''
      CREATE TABLE loans (
        id TEXT PRIMARY KEY,
        userId TEXT,
        loanId TEXT,
        type TEXT,
        status TEXT DEFAULT 'Pending',
        amountValue INTEGER DEFAULT 0,
        remainingBalanceValue INTEGER DEFAULT 0,
        period TEXT,
        purpose TEXT,
        nextPaymentDate TEXT,
        repaymentProgress INTEGER DEFAULT 0,
        createdAt TEXT,
        updatedAt TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Loan Applications table
    await db.execute('''
      CREATE TABLE loan_applications (
        id TEXT PRIMARY KEY,
        applicationId TEXT,
        userId TEXT,
        userName TEXT,
        userEmail TEXT,
        userPhone TEXT,
        customerId TEXT,
        loanType TEXT,
        amountValue INTEGER,
        period TEXT,
        purpose TEXT,
        status TEXT DEFAULT 'Pending Review',
        rejectionReason TEXT,
        reviewedBy TEXT,
        reviewedAt TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        userId TEXT,
        title TEXT,
        subtitle TEXT,
        amountValue INTEGER,
        isCredit INTEGER DEFAULT 0,
        createdAt TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        userId TEXT,
        title TEXT,
        message TEXT,
        type TEXT DEFAULT 'info',
        isRead INTEGER DEFAULT 0,
        createdAt TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Admin requests table
    await db.execute('''
      CREATE TABLE admin_requests (
        id TEXT PRIMARY KEY,
        requestId TEXT,
        type TEXT,
        userId TEXT,
        userName TEXT,
        userEmail TEXT,
        status TEXT DEFAULT 'Pending Review',
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
  }

  // User operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertUsers(List<Map<String, dynamic>> users) async {
    if (users.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final user in users) {
      batch.insert('users', user, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateUser(String userId, Map<String, dynamic> user) async {
    final db = await database;
    return await db.update('users', user, where: 'id = ?', whereArgs: [userId]);
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users', orderBy: 'createdAt DESC');
  }

  Future<int> deleteUser(String userId) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  Future<void> deleteUserRelatedData(String userId) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('loan_applications', where: 'userId = ?', whereArgs: [userId]);
    batch.delete('loans', where: 'userId = ?', whereArgs: [userId]);
    batch.delete('transactions', where: 'userId = ?', whereArgs: [userId]);
    batch.delete('notifications', where: 'userId = ?', whereArgs: [userId]);
    batch.delete('admin_requests', where: 'userId = ?', whereArgs: [userId]);
    batch.delete('users', where: 'id = ?', whereArgs: [userId]);
    await batch.commit(noResult: true);
  }

  // Loan operations
  Future<int> insertLoan(Map<String, dynamic> loan) async {
    final db = await database;
    return await db.insert(
      'loans',
      loan,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getActiveLoan(String userId) async {
    final db = await database;
    final results = await db.query(
      'loans',
      where: 'userId = ? AND status = ?',
      whereArgs: [userId, 'Active'],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getLatestLoanForUser(String userId) async {
    final db = await database;
    final results = await db.query(
      'loans',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'updatedAt DESC, createdAt DESC',
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateLoan(String loanId, Map<String, dynamic> loan) async {
    final db = await database;
    return await db.update('loans', loan, where: 'id = ?', whereArgs: [loanId]);
  }

  // Loan Application operations
  Future<int> insertLoanApplication(Map<String, dynamic> app) async {
    final db = await database;
    return await db.insert(
      'loan_applications',
      app,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertLoanApplications(List<Map<String, dynamic>> apps) async {
    if (apps.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final app in apps) {
      batch.insert(
        'loan_applications',
        app,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getLoanApplications(String userId) async {
    final db = await database;
    return await db.query(
      'loan_applications',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getLoanApplicationsPaged(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await database;
    return await db.query(
      'loan_applications',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getAllLoanApplications() async {
    final db = await database;
    return await db.query('loan_applications', orderBy: 'createdAt DESC');
  }

  Future<Map<String, dynamic>?> getLoanApplication(String applicationId) async {
    final db = await database;
    final results = await db.query(
      'loan_applications',
      where: 'applicationId = ?',
      whereArgs: [applicationId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateLoanApplication(
    String applicationId,
    Map<String, dynamic> app,
  ) async {
    final db = await database;
    return await db.update(
      'loan_applications',
      app,
      where: 'applicationId = ?',
      whereArgs: [applicationId],
    );
  }

  // Transaction operations
  Future<int> insertTransaction(Map<String, dynamic> tx) async {
    final db = await database;
    return await db.insert('transactions', tx);
  }

  Future<void> upsertTransactions(
    List<Map<String, dynamic>> transactions,
  ) async {
    if (transactions.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final tx in transactions) {
      batch.insert(
        'transactions',
        tx,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getTransactions(
    String userId, {
    int limit = 100,
  }) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getTransactionsPaged(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
      limit: limit,
      offset: offset,
    );
  }

  // Notification operations
  Future<int> insertNotification(Map<String, dynamic> notif) async {
    final db = await database;
    return await db.insert('notifications', notif);
  }

  Future<void> upsertNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    if (notifications.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final notif in notifications) {
      batch.insert(
        'notifications',
        notif,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getNotifications(
    String userId, {
    int limit = 100,
  }) async {
    final db = await database;
    return await db.query(
      'notifications',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getNotificationsPaged(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await database;
    return await db.query(
      'notifications',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<int> markNotificationRead(String notifId) async {
    final db = await database;
    return await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [notifId],
    );
  }

  Future<int> markAllNotificationsRead(String userId) async {
    final db = await database;
    return await db.update(
      'notifications',
      {'isRead': 1},
      where: 'userId = ? AND isRead = 0',
      whereArgs: [userId],
    );
  }

  // Admin Request operations
  Future<int> insertAdminRequest(Map<String, dynamic> req) async {
    final db = await database;
    return await db.insert(
      'admin_requests',
      req,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllAdminRequests() async {
    final db = await database;
    return await db.query('admin_requests', orderBy: 'createdAt DESC');
  }

  Future<int> updateAdminRequest(
    String requestId,
    Map<String, dynamic> req,
  ) async {
    final db = await database;
    return await db.update(
      'admin_requests',
      req,
      where: 'requestId = ?',
      whereArgs: [requestId],
    );
  }

  // Admin: Get all users (for admin dashboard)
  Future<List<Map<String, dynamic>>> getAllUsersForAdmin() async {
    final db = await database;
    return await db.query('users', orderBy: 'createdAt DESC');
  }

  // Admin: Get pending loan count
  Future<int> getPendingLoansCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM loan_applications WHERE status = 'Pending Review'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getActiveLoansCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM loan_applications WHERE status = 'Approved' OR status = 'Active'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getAllLoansForAdmin() async {
    final db = await database;
    return await db.query('loans', orderBy: 'updatedAt DESC, createdAt DESC');
  }

  Future<int> getTotalUserBalances() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(balanceValue), 0) as total FROM users',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getRecentUsersForAdmin({
    int limit = 5,
  }) async {
    final db = await database;
    return await db.query('users', orderBy: 'createdAt DESC', limit: limit);
  }

  // Get total users count
  Future<int> getTotalUsersCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
