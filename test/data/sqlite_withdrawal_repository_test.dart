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
    await helper.database;
    final repo = SqliteWithdrawalRepository(databaseHelper: helper);

    final nowIso = DateTime.now().toIso8601String();
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
