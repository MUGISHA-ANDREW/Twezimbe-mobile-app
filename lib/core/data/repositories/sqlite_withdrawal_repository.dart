import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:twezimbeapp/core/data/app_logger.dart';
import 'package:twezimbeapp/core/data/change_bus.dart';
import 'package:twezimbeapp/core/data/data_exceptions.dart';
import 'package:twezimbeapp/core/data/database_helper.dart';
import 'package:twezimbeapp/core/data/db_constants.dart';
import 'package:twezimbeapp/core/data/models/ledger_entry_model.dart';
import 'package:twezimbeapp/core/data/models/withdrawal_model.dart';
import 'package:twezimbeapp/core/data/repositories/withdrawal_repository.dart';

/// SQLite implementation of WithdrawalRepository.
class SqliteWithdrawalRepository implements WithdrawalRepository {
  SqliteWithdrawalRepository({DatabaseHelper? databaseHelper})
      : _db = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _db;
  final DatabaseChangeBus _bus = DatabaseChangeBus.instance;

  @override
  Stream<List<WithdrawalModel>> watchWithdrawals(
    String userId, {
    int limit = 100,
  }) {
    final controller = StreamController<List<WithdrawalModel>>.broadcast();
    StreamSubscription<String>? sub;

    Future<void> emit() async {
      final db = await _db.readOnlyDatabase;
      final rows = await db.query(
        DbTables.withdrawals,
        where: '${DbColumns.userId} = ?',
        whereArgs: [userId],
        orderBy: '${DbColumns.createdAt} DESC',
        limit: limit,
      );
      controller.add(rows.map(WithdrawalModel.fromMap).toList());
    }

    controller.onListen = () {
      unawaited(emit());
      sub = _bus.stream
          .where((table) => table == DbTables.withdrawals)
          .listen((_) => unawaited(emit()));
    };

    controller.onCancel = () async {
      await sub?.cancel();
    };

    return controller.stream;
  }

  @override
  Future<void> insertWithdrawal(WithdrawalModel withdrawal) async {
    await _db.runInTransaction((txn) async {
      final nowIso = DateTime.now().toIso8601String();
      final data = withdrawal.toMap()
        ..[DbColumns.createdAt] = nowIso
        ..[DbColumns.updatedAt] = nowIso
        ..[DbColumns.syncStatus] = DbSyncStatus.pendingSync;
      await txn.insert(DbTables.withdrawals, data);
      await _enqueueSync(
        txn,
        DbTables.withdrawals,
        withdrawal.id,
        DbOperations.insert,
        data,
      );
    });

    _bus.notify(DbTables.withdrawals);
  }

  @override
  Future<void> updateWithdrawal(WithdrawalModel withdrawal) async {
    await _db.runInTransaction((txn) async {
      final rows = await txn.query(
        DbTables.withdrawals,
        where: '${DbColumns.id} = ?',
        whereArgs: [withdrawal.id],
      );
      if (rows.isEmpty) {
        throw const RecordNotFoundException('Withdrawal not found');
      }
      final currentVersion =
          (rows.first[DbColumns.version] as num?)?.toInt() ?? 0;
      final data = withdrawal.toMap()
        ..[DbColumns.updatedAt] = DateTime.now().toIso8601String()
        ..[DbColumns.version] = currentVersion + 1
        ..[DbColumns.syncStatus] = DbSyncStatus.pendingSync;
      final updated = await txn.update(
        DbTables.withdrawals,
        data,
        where: '${DbColumns.id} = ? AND ${DbColumns.version} = ?',
        whereArgs: [withdrawal.id, currentVersion],
      );
      if (updated == 0) {
        throw const DatabaseException('Withdrawal update conflict');
      }
      await _enqueueSync(
        txn,
        DbTables.withdrawals,
        withdrawal.id,
        DbOperations.update,
        data,
      );
    });

    _bus.notify(DbTables.withdrawals);
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
