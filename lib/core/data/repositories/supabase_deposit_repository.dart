import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twezimbeapp/core/data/change_bus.dart';
import 'package:twezimbeapp/core/data/db_constants.dart';
import 'package:twezimbeapp/core/data/models/deposit_model.dart';
import 'package:twezimbeapp/core/data/models/deposit_transaction_model.dart';
import 'package:twezimbeapp/core/data/models/ledger_entry_model.dart';
import 'package:twezimbeapp/core/data/repositories/deposit_repository.dart';

void logSupabaseError(String context, Object error) {
  print('❌ SUPABASE ERROR in $context');
  print(error);

  if (error is PostgrestException) {
    print('Code: ${error.code}');
    print('Message: ${error.message}');
    print('Details: ${error.details}');
    print('Hint: ${error.hint}');
  }
}

class SupabaseDepositRepository implements DepositRepository {
  static SupabaseClient get _client => Supabase.instance.client;
  final DatabaseChangeBus _bus = DatabaseChangeBus.instance;

  static bool _isUuid(String? id) =>
      id != null &&
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(id);

  @override
  Stream<List<DepositModel>> watchDeposits(String userId, {int limit = 100}) {
    final controller = StreamController<List<DepositModel>>.broadcast();
    StreamSubscription<String>? sub;

    Future<void> emit() async {
      try {
        final rows = await _client
            .from('deposits')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(limit);

        print('✅ deposits fetched: ${rows.length}');

        controller.add(
          (rows as List).map((row) => DepositModel.fromMap(row)).toList(),
        );
      } catch (e) {
        logSupabaseError('watchDeposits', e);
        controller.add([]);
      }
    }

    controller.onListen = () {
      unawaited(emit());
      sub = _bus.stream
          .where((t) => t == DbTables.deposits)
          .listen((_) => unawaited(emit()));
    };
    controller.onCancel = () async => sub?.cancel();
    return controller.stream;
  }

  @override
  Future<void> insertDeposit(DepositModel deposit) async {
    final nowIso = DateTime.now().toIso8601String();

    final payload = {
      'user_id': deposit.userId,
      'account_id': _isUuid(deposit.accountId) ? deposit.accountId : null,
      'amount_value': deposit.amountValue,
      'method': deposit.method,
      'status': deposit.status,
      'reference': deposit.reference,
      'created_at': deposit.createdAt.isNotEmpty ? deposit.createdAt : nowIso,
      'updated_at': deposit.updatedAt.isNotEmpty ? deposit.updatedAt : nowIso,
      'sync_status': DbSyncStatus.synced,
      'version': 0,
    };

    print('➡️ inserting deposit: $payload');

    try {
      final res = await _client.from('deposits').insert(payload).select();

      print('✅ deposit inserted: $res');
      _bus.notify(DbTables.deposits);
    } catch (e) {
      logSupabaseError('insertDeposit', e);
      rethrow;
    }
  }

  @override
  Future<void> insertDepositTransactions(
    List<DepositTransactionModel> items,
  ) async {
    // deposit_transactions table not in Supabase schema; skip silently
  }

  @override
  Future<void> insertLedgerEntries(List<LedgerEntryModel> entries) async {
    if (entries.isEmpty) return;

    final nowIso = DateTime.now().toIso8601String();

    final payload = entries.map((e) {
      return {
        'user_id': e.userId,
        'account_id': _isUuid(e.accountId) ? e.accountId : null,
        'amount_value': e.amountValue,
        'entry_type': e.entryType,
        'reference_type': e.referenceType,
        'reference_id': e.referenceId,
        'created_at': e.createdAt.isNotEmpty ? e.createdAt : nowIso,
        'updated_at': e.updatedAt.isNotEmpty ? e.updatedAt : nowIso,
        'sync_status': DbSyncStatus.synced,
        'version': 0,
      };
    }).toList();

    print('➡️ inserting ledger_entries: $payload');

    try {
      final res = await _client.from('ledger_entries').insert(payload).select();
      print('✅ ledger inserted: $res');

      _bus.notify(DbTables.ledgerEntries);
    } catch (e) {
      logSupabaseError('insertLedgerEntries', e);
      rethrow;
    }
  }
}
