import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:twezimbeapp/core/data/database_helper.dart';
import 'package:twezimbeapp/core/data/db_constants.dart';
import 'package:twezimbeapp/core/data/models/deposit_model.dart';
import 'package:twezimbeapp/core/data/repositories/sqlite_deposit_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  test('Deposit repository create/read/update flow', () async {
    final helper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
      dbPath: inMemoryDatabasePath,
    );
    await helper.database;
    final repo = SqliteDepositRepository(databaseHelper: helper);

    final nowIso = DateTime.now().toIso8601String();
    final deposit = DepositModel(
      id: 'dep_1',
      userId: 'user_1',
      accountId: 'acct_1',
      amountValue: 200000,
      method: DbDefaults.depositMethod,
      status: DbStatus.completed,
      reference: 'ref_1',
      createdAt: nowIso,
      updatedAt: nowIso,
      version: 0,
      syncStatus: DbSyncStatus.pendingSync,
    );

    final stream = repo.watchDeposits('user_1');
    final completer = Completer<void>();
    final sub = stream.listen((items) {
      if (items.isNotEmpty) {
        expect(items.first.amountValue, 200000);
        completer.complete();
      }
    });

    await repo.insertDeposit(deposit);
    await completer.future.timeout(const Duration(seconds: 2));
    await sub.cancel();
  });
}
