import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:twezimbeapp/core/data/database_helper.dart';
import 'package:twezimbeapp/core/data/db_constants.dart';
import 'package:twezimbeapp/core/data/models/deposit_model.dart';
import 'package:twezimbeapp/core/data/repositories/sqlite_deposit_repository.dart';

class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockTransaction extends Mock implements sqflite.Transaction {}

void main() {
  setUpAll(() {
    registerFallbackValue('');
    registerFallbackValue(<String, Object?>{});
    registerFallbackValue((sqflite.Transaction _) async {});
  });

  test('SqliteDepositRepository uses DatabaseHelper transaction', () async {
    final mockHelper = MockDatabaseHelper();
    final mockTxn = MockTransaction();

    when(() => mockTxn.insert(any(), any())).thenAnswer((_) async => 1);

    when(() => mockHelper.runInTransaction<dynamic>(any())).thenAnswer((
      invocation,
    ) async {
      final action =
          invocation.positionalArguments.first
              as Future<dynamic> Function(sqflite.Transaction);
      return action(mockTxn);
    });

    final repo = SqliteDepositRepository(databaseHelper: mockHelper);

    await repo.insertDeposit(
      const DepositModel(
        id: 'dep_mock',
        userId: 'user_mock',
        accountId: 'acct_mock',
        amountValue: 1000,
        method: DbDefaults.depositMethod,
        status: DbStatus.completed,
        reference: 'ref_mock',
        createdAt: '2026-01-01T00:00:00.000Z',
        updatedAt: '2026-01-01T00:00:00.000Z',
        version: 0,
        syncStatus: DbSyncStatus.pendingSync,
      ),
    );

    verify(() => mockHelper.runInTransaction<dynamic>(any())).called(1);
  });
}
