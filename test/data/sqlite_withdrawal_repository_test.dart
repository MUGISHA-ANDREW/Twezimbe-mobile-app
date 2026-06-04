import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:twezimbeapp/core/data/database_helper.dart';
import 'package:twezimbeapp/core/data/db_constants.dart';
import 'package:twezimbeapp/core/data/models/withdrawal_model.dart';
import 'package:twezimbeapp/core/data/repositories/sqlite_withdrawal_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  test('Withdrawal repository create/read/update flow', () async {
    final helper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
      dbPath: inMemoryDatabasePath,
    );
    final db = await helper.database;
    final repo = SqliteWithdrawalRepository(databaseHelper: helper);

    final nowIso = DateTime.now().toIso8601String();
    await db.insert(DbTables.users, {
      DbColumns.id: 'user_1',
      DbColumns.fullName: 'Test User',
      DbColumns.email: 'user@test.local',
      DbColumns.phoneNumber: '0700000000',
      DbColumns.kycStatus: 'Pending',
      DbColumns.accountType: 'Savings Account',
      DbColumns.balanceValue: 0,
      DbColumns.isAdmin: 0,
      DbColumns.createdAt: nowIso,
      DbColumns.updatedAt: nowIso,
      DbColumns.isDeleted: 0,
      DbColumns.syncStatus: DbSyncStatus.pendingSync,
      DbColumns.version: 0,
    });
    await db.insert(DbTables.accounts, {
      DbColumns.id: 'acct_1',
      DbColumns.userId: 'user_1',
      DbColumns.accountType: 'Savings Account',
      DbColumns.balanceValue: 0,
      DbColumns.status: DbDefaults.accountStatus,
      'currency': DbDefaults.currency,
      DbColumns.createdAt: nowIso,
      DbColumns.updatedAt: nowIso,
      DbColumns.isDeleted: 0,
      DbColumns.syncStatus: DbSyncStatus.pendingSync,
      DbColumns.version: 0,
    });
    final withdrawal = WithdrawalModel(
      id: 'wd_1',
      userId: 'user_1',
      accountId: 'acct_1',
      amountValue: 50000,
      method: DbDefaults.withdrawalMethod,
      status: DbStatus.pending,
      reference: 'ref_1',
      requestedAt: nowIso,
      processedAt: '',
      createdAt: nowIso,
      updatedAt: nowIso,
      version: 0,
      syncStatus: DbSyncStatus.pendingSync,
    );

    final stream = repo.watchWithdrawals('user_1');
    final completer = Completer<void>();
    final sub = stream.listen((items) {
      if (items.isNotEmpty) {
        expect(items.first.status, DbStatus.pending);
        completer.complete();
      }
    });

    await repo.insertWithdrawal(withdrawal);
    await completer.future.timeout(const Duration(seconds: 2));
    await sub.cancel();
  });
}
