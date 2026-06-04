import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:twezimbeapp/core/data/app_logger.dart';
import 'package:twezimbeapp/core/data/change_bus.dart';
import 'package:twezimbeapp/core/data/data_exceptions.dart';
import 'package:twezimbeapp/core/data/database_helper.dart';
import 'package:twezimbeapp/core/data/db_constants.dart';
import 'package:twezimbeapp/core/data/models/ledger_entry_model.dart';
import 'package:twezimbeapp/core/data/models/loan_application_model.dart';
import 'package:twezimbeapp/core/data/models/loan_model.dart';
import 'package:twezimbeapp/core/data/models/loan_product_model.dart';
import 'package:twezimbeapp/core/data/models/loan_repayment_model.dart';
import 'package:twezimbeapp/core/data/repositories/loan_repository.dart';

/// SQLite implementation of LoanRepository.
class SqliteLoanRepository implements LoanRepository {
  SqliteLoanRepository({DatabaseHelper? databaseHelper})
    : _db = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _db;
  final DatabaseChangeBus _bus = DatabaseChangeBus.instance;
  final Map<String, List<LoanProductModel>> _loanProductsCache = {};

  @override
  Stream<LoanModel?> watchActiveLoan(String userId) {
    final controller = StreamController<LoanModel?>.broadcast();
    StreamSubscription<String>? sub;

    Future<void> emit() async {
      final db = await _db.readOnlyDatabase;
      final rows = await db.query(
        DbTables.loans,
        where: '${DbColumns.userId} = ? AND ${DbColumns.status} = ?',
        whereArgs: [userId, DbStatus.active],
        orderBy: '${DbColumns.updatedAt} DESC',
        limit: 1,
      );
      if (rows.isEmpty) {
        controller.add(null);
        return;
      }
      controller.add(LoanModel.fromMap(rows.first));
    }

    controller.onListen = () {
      unawaited(emit());
      sub = _bus.stream.where((table) => table == DbTables.loans).listen((_) {
        unawaited(emit());
      });
    };

    controller.onCancel = () async {
      await sub?.cancel();
    };

    return controller.stream;
  }

  @override
  Stream<List<LoanApplicationModel>> watchLoanApplications(
    String userId, {
    int limit = 100,
  }) {
    final controller = StreamController<List<LoanApplicationModel>>.broadcast();
    StreamSubscription<String>? sub;

    Future<void> emit() async {
      final db = await _db.readOnlyDatabase;
      final rows = await db.query(
        DbTables.loanApplications,
        where: '${DbColumns.userId} = ?',
        whereArgs: [userId],
        orderBy: '${DbColumns.createdAt} DESC',
        limit: limit,
      );
      controller.add(rows.map(LoanApplicationModel.fromMap).toList());
    }

    controller.onListen = () {
      unawaited(emit());
      sub = _bus.stream
          .where((table) => table == DbTables.loanApplications)
          .listen((_) => unawaited(emit()));
    };

    controller.onCancel = () async {
      await sub?.cancel();
    };

    return controller.stream;
  }

  @override
  Future<LoanModel?> getLatestLoan(String userId) async {
    final db = await _db.readOnlyDatabase;
    final rows = await db.query(
      DbTables.loans,
      where: '${DbColumns.userId} = ?',
      whereArgs: [userId],
      orderBy: '${DbColumns.updatedAt} DESC, ${DbColumns.createdAt} DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return LoanModel.fromMap(rows.first);
  }

  @override
  Future<void> upsertLoan(LoanModel loan) async {
    await _db.runInTransaction((txn) async {
      final rows = await txn.query(
        DbTables.loans,
        where: '${DbColumns.id} = ?',
        whereArgs: [loan.id],
      );

      final nowIso = DateTime.now().toIso8601String();
      if (rows.isEmpty) {
        final data = loan.toMap()
          ..[DbColumns.createdAt] = nowIso
          ..[DbColumns.updatedAt] = nowIso
          ..[DbColumns.syncStatus] = DbSyncStatus.pendingSync;
        await txn.insert(DbTables.loans, data);
        await _enqueueSync(
          txn,
          DbTables.loans,
          loan.id,
          DbOperations.insert,
          data,
        );
      } else {
        final currentVersion =
            (rows.first[DbColumns.version] as num?)?.toInt() ?? 0;
        final data = loan.toMap()
          ..[DbColumns.updatedAt] = nowIso
          ..[DbColumns.version] = currentVersion + 1
          ..[DbColumns.syncStatus] = DbSyncStatus.pendingSync;
        final updated = await txn.update(
          DbTables.loans,
          data,
          where: '${DbColumns.id} = ? AND ${DbColumns.version} = ?',
          whereArgs: [loan.id, currentVersion],
        );
        if (updated == 0) {
          throw const DatabaseException('Loan update conflict detected');
        }
        await _enqueueSync(
          txn,
          DbTables.loans,
          loan.id,
          DbOperations.update,
          data,
        );
      }
    });

    _bus.notify(DbTables.loans);
  }

  @override
  Future<void> upsertLoanApplication(LoanApplicationModel application) async {
    await _db.runInTransaction((txn) async {
      final rows = await txn.query(
        DbTables.loanApplications,
        where: '${DbColumns.id} = ?',
        whereArgs: [application.id],
      );

      final nowIso = DateTime.now().toIso8601String();
      if (rows.isEmpty) {
        final data = application.toMap()
          ..[DbColumns.createdAt] = nowIso
          ..[DbColumns.updatedAt] = nowIso
          ..[DbColumns.syncStatus] = DbSyncStatus.pendingSync;
        await txn.insert(DbTables.loanApplications, data);
        await _enqueueSync(
          txn,
          DbTables.loanApplications,
          application.id,
          DbOperations.insert,
          data,
        );
      } else {
        final currentVersion =
            (rows.first[DbColumns.version] as num?)?.toInt() ?? 0;
        final data = application.toMap()
          ..[DbColumns.updatedAt] = nowIso
          ..[DbColumns.version] = currentVersion + 1
          ..[DbColumns.syncStatus] = DbSyncStatus.pendingSync;
        final updated = await txn.update(
          DbTables.loanApplications,
          data,
          where: '${DbColumns.id} = ? AND ${DbColumns.version} = ?',
          whereArgs: [application.id, currentVersion],
        );
        if (updated == 0) {
          throw const DatabaseException('Loan application update conflict');
        }
        await _enqueueSync(
          txn,
          DbTables.loanApplications,
          application.id,
          DbOperations.update,
          data,
        );
      }
    });

    _bus.notify(DbTables.loanApplications);
  }

  @override
  Future<void> updateLoanApplication(LoanApplicationModel application) async {
    await upsertLoanApplication(application);
  }

  @override
  Future<LoanApplicationModel?> getLoanApplication(String applicationId) async {
    final db = await _db.readOnlyDatabase;
    final rows = await db.query(
      DbTables.loanApplications,
      where: '(${DbColumns.applicationId} = ? OR ${DbColumns.id} = ?)',
      whereArgs: [applicationId, applicationId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return LoanApplicationModel.fromMap(rows.first);
  }

  @override
  Future<void> insertLoanRepayment(LoanRepaymentModel repayment) async {
    await _db.runInTransaction((txn) async {
      final data = repayment.toMap()
        ..[DbColumns.syncStatus] = DbSyncStatus.pendingSync;
      await txn.insert(DbTables.loanRepayments, data);
      await _enqueueSync(
        txn,
        DbTables.loanRepayments,
        repayment.id,
        DbOperations.insert,
        data,
      );
    });

    _bus.notify(DbTables.loanRepayments);
  }

  @override
  Future<void> insertLedgerEntries(List<LedgerEntryModel> entries) async {
    if (entries.isEmpty) return;
    await _db.runInTransaction((txn) async {
      final batch = txn.batch();
      for (final entry in entries) {
        final data = entry.toMap()
          ..[DbColumns.syncStatus] = DbSyncStatus.pendingSync;
        batch.insert(DbTables.ledgerEntries, data);
        batch.insert(DbTables.pendingSyncQueue, {
          DbColumns.id: 'sync_${entry.id}',
          'table_name': DbTables.ledgerEntries,
          'record_id': entry.id,
          DbColumns.operation: DbOperations.insert,
          DbColumns.payloadJson: jsonEncode(data),
          DbColumns.createdAt: DateTime.now().toIso8601String(),
        });
      }
      await batch.commit(noResult: true);
    });

    _bus.notify(DbTables.ledgerEntries);
  }

  @override
  Future<List<LoanProductModel>> getLoanProducts({bool refresh = false}) async {
    if (!refresh && _loanProductsCache.containsKey('all')) {
      return _loanProductsCache['all']!;
    }

    final db = await _db.readOnlyDatabase;
    final rows = await db.query(DbTables.loanProducts, orderBy: 'name ASC');
    final products = rows.map(LoanProductModel.fromMap).toList();
    _loanProductsCache['all'] = products;
    return products;
  }

  @override
  Future<void> upsertLoanProducts(List<LoanProductModel> products) async {
    if (products.isEmpty) return;
    await _db.runInTransaction((txn) async {
      final batch = txn.batch();
      for (final product in products) {
        final data = product.toMap()
          ..[DbColumns.syncStatus] = DbSyncStatus.pendingSync;
        batch.insert(
          DbTables.loanProducts,
          data,
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
        batch.insert(DbTables.pendingSyncQueue, {
          DbColumns.id: 'sync_${product.id}',
          'table_name': DbTables.loanProducts,
          'record_id': product.id,
          DbColumns.operation: DbOperations.insert,
          DbColumns.payloadJson: jsonEncode(data),
          DbColumns.createdAt: DateTime.now().toIso8601String(),
        });
      }
      await batch.commit(noResult: true);
    });

    _loanProductsCache.remove('all');
  }

  Future<void> _enqueueSync(
    sqflite.Transaction txn,
    String table,
    String recordId,
    String operation,
    Map<String, dynamic> payload,
  ) async {
    try {
      await txn.insert(
        DbTables.pendingSyncQueue,
        {
          DbColumns.id: 'sync_${table}_$recordId',
          'table_name': table,
          'record_id': recordId,
          DbColumns.operation: operation,
          DbColumns.payloadJson: jsonEncode(payload),
          DbColumns.createdAt: DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    } catch (error) {
      AppLogger.instance.w('Pending sync enqueue failed: $error');
    }
  }
}
