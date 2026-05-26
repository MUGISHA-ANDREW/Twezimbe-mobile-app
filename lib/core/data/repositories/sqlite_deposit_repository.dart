import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:twezimbeapp/core/data/app_logger.dart';
import 'package:twezimbeapp/core/data/change_bus.dart';
import 'package:twezimbeapp/core/data/database_helper.dart';
import 'package:twezimbeapp/core/data/db_constants.dart';
import 'package:twezimbeapp/core/data/models/deposit_model.dart';
import 'package:twezimbeapp/core/data/models/deposit_transaction_model.dart';
import 'package:twezimbeapp/core/data/models/ledger_entry_model.dart';
import 'package:twezimbeapp/core/data/repositories/deposit_repository.dart';

/// SQLite implementation of DepositRepository.
class SqliteDepositRepository implements DepositRepository {
  SqliteDepositRepository({DatabaseHelper? databaseHelper})
      : _db = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _db;
  final DatabaseChangeBus _bus = DatabaseChangeBus.instance;

  @override
  Stream<List<DepositModel>> watchDeposits(String userId, {int limit = 100}) {
    final controller = StreamController<List<DepositModel>>.broadcast();
    StreamSubscription<String>? sub;

    Future<void> emit() async {
      final db = await _db.readOnlyDatabase;
      final rows = await db.query(
        DbTables.deposits,
        where: '${DbColumns.userId} = ?',
        whereArgs: [userId],
        orderBy: '${DbColumns.createdAt} DESC',
        limit: limit,
      );
      controller.add(rows.map(DepositModel.fromMap).toList());
    }

    controller.onListen = () {
      unawaited(emit());
      sub = _bus.stream.where((table) => table == DbTables.deposits).listen((_) {
        unawaited(emit());
      });
    };

    controller.onCancel = () async {
      await sub?.cancel();
    };

    return controller.stream;
  }

  @override
  Future<void> insertDeposit(DepositModel deposit) async {
    await _db.runInTransaction((txn) async {
      final nowIso = DateTime.now().toIso8601String();
      final data = deposit.toMap()
        ..[DbColumns.createdAt] = nowIso
        ..[DbColumns.updatedAt] = nowIso
        ..[DbColumns.syncStatus] = DbSyncStatus.pendingSync;
      await txn.insert(DbTables.deposits, data);
      await _enqueueSync(txn, DbTables.deposits, deposit.id, DbOperations.insert, data);
    });

    _bus.notify(DbTables.deposits);
  }

  @override
  Future<void> insertDepositTransactions(
    List<DepositTransactionModel> items,
  ) async {
    if (items.isEmpty) return;
    await _db.runInTransaction((txn) async {
      final batch = txn.batch();
      for (final item in items) {
        final data = item.toMap()
          ..[DbColumns.syncStatus] = DbSyncStatus.pendingSync;
        batch.insert(DbTables.depositTransactions, data);
        batch.insert(DbTables.pendingSyncQueue, {
          DbColumns.id: 'sync_${item.id}',
          'table_name': DbTables.depositTransactions,
          'record_id': item.id,
          DbColumns.operation: DbOperations.insert,
          DbColumns.payloadJson: jsonEncode(data),
          DbColumns.createdAt: DateTime.now().toIso8601String(),
        });
      }
      await batch.commit(noResult: true);
    });

    _bus.notify(DbTables.depositTransactions);
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

  Future<void> _enqueueSync(
    sqflite.Transaction txn,
    String table,
    String recordId,
    String operation,
    Map<String, dynamic> payload,
  ) async {
    try {
      await txn.insert(DbTables.pendingSyncQueue, {
        DbColumns.id: 'sync_${table}_$recordId',
        'table_name': table,
        'record_id': recordId,
        DbColumns.operation: operation,
        DbColumns.payloadJson: jsonEncode(payload),
        DbColumns.createdAt: DateTime.now().toIso8601String(),
      }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
    } catch (error) {
      AppLogger.instance.w('Pending sync enqueue failed: $error');
    }
  }
}
