import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:twezimbeapp/core/data/database_helper.dart';
import 'package:twezimbeapp/core/data/db_constants.dart';
import 'package:twezimbeapp/core/data/models/loan_application_model.dart';
import 'package:twezimbeapp/core/data/models/loan_model.dart';
import 'package:twezimbeapp/core/data/models/loan_repayment_model.dart';
import 'package:twezimbeapp/core/data/repositories/sqlite_loan_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  test('Loan repository CRUD flow', () async {
    final helper = DatabaseHelper.forTesting(
      databaseFactory: databaseFactoryFfi,
      dbPath: inMemoryDatabasePath,
    );
    final db = await helper.database;
    final repo = SqliteLoanRepository(databaseHelper: helper);

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
    final application = LoanApplicationModel(
      id: 'app_1',
      applicationId: 'app_1',
      userId: 'user_1',
      userName: 'Test User',
      userEmail: 'user@test.local',
      userPhone: '0700000000',
      customerId: 'CUS00001',
      loanType: 'Salary Loan',
      amountValue: 500000,
      period: '12 months',
      purpose: 'Working capital',
      status: DbStatus.pending,
      rejectionReason: '',
      reviewedBy: '',
      reviewedAt: nowIso,
      createdAt: nowIso,
      updatedAt: nowIso,
      version: 0,
      syncStatus: DbSyncStatus.pendingSync,
    );

    await repo.upsertLoanApplication(application);
    final fetchedApp = await repo.getLoanApplication('app_1');
    expect(fetchedApp, isNotNull);
    expect(fetchedApp!.status, DbStatus.pending);

    final loan = LoanModel(
      id: 'loan_1',
      userId: 'user_1',
      loanId: 'LN0001',
      type: 'Salary Loan',
      status: DbStatus.active,
      amountValue: 500000,
      remainingBalanceValue: 500000,
      period: '12 months',
      purpose: 'Working capital',
      nextPaymentDate: nowIso,
      repaymentProgress: 0,
      createdAt: nowIso,
      updatedAt: nowIso,
      version: 0,
      syncStatus: DbSyncStatus.pendingSync,
    );

    await repo.upsertLoan(loan);
    final latest = await repo.getLatestLoan('user_1');
    expect(latest, isNotNull);
    expect(latest!.remainingBalanceValue, 500000);

    await repo.insertLoanRepayment(
      LoanRepaymentModel(
        id: 'rep_1',
        loanId: loan.id,
        userId: 'user_1',
        amountValue: 100000,
        method: DbDefaults.repaymentMethod,
        status: DbStatus.completed,
        paidAt: nowIso,
        createdAt: nowIso,
        updatedAt: nowIso,
        version: 0,
        syncStatus: DbSyncStatus.pendingSync,
      ),
    );
  });
}
