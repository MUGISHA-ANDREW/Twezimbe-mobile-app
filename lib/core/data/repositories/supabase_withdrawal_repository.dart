import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twezimbeapp/core/data/change_bus.dart';
import 'package:twezimbeapp/core/data/db_constants.dart';
import 'package:twezimbeapp/core/data/models/ledger_entry_model.dart';
import 'package:twezimbeapp/core/data/models/withdrawal_model.dart';
import 'package:twezimbeapp/core/data/repositories/withdrawal_repository.dart';

class SupabaseWithdrawalRepository implements WithdrawalRepository {
  static SupabaseClient get _client => Supabase.instance.client;
  final DatabaseChangeBus _bus = DatabaseChangeBus.instance;

  static bool _isUuid(String? id) =>
      id != null &&
      RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(id);

  @override
  Stream<List<WithdrawalModel>> watchWithdrawals(
    String userId, {
    int limit = 100,
  }) {
    final controller = StreamController<List<WithdrawalModel>>.broadcast();
    StreamSubscription<String>? sub;

    Future<void> emit() async {
      try {
        final rows = await _client
            .from('withdrawals')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(limit);
        controller.add(rows.map(WithdrawalModel.fromMap).toList());
      } catch (_) {
        controller.add([]);
      }
    }

    controller.onListen = () {
      unawaited(emit());
      sub = _bus.stream
          .where((t) => t == DbTables.withdrawals)
          .listen((_) => unawaited(emit()));
    };
    controller.onCancel = () async => sub?.cancel();
    return controller.stream;
  }

  @override
  Future<void> insertWithdrawal(WithdrawalModel withdrawal) async {
    final nowIso = DateTime.now().toIso8601String();
    try {
      await _client.from('withdrawals').insert({
        'user_id': withdrawal.userId,
        'account_id': _isUuid(withdrawal.accountId) ? withdrawal.accountId : null,
        'amount_value': withdrawal.amountValue,
        'method': withdrawal.method,
        'status': withdrawal.status,
        'reference': withdrawal.reference,
        'requested_at':
            withdrawal.requestedAt.isNotEmpty ? withdrawal.requestedAt : null,
        'processed_at':
            withdrawal.processedAt.isNotEmpty ? withdrawal.processedAt : null,
        'created_at': withdrawal.createdAt.isNotEmpty ? withdrawal.createdAt : nowIso,
        'updated_at': withdrawal.updatedAt.isNotEmpty ? withdrawal.updatedAt : nowIso,
        'sync_status': DbSyncStatus.synced,
        'version': 0,
      });
      _bus.notify(DbTables.withdrawals);
    } catch (_) {}
  }

  @override
  Future<void> updateWithdrawal(WithdrawalModel withdrawal) async {
    if (!_isUuid(withdrawal.id)) return;
    try {
      await _client.from('withdrawals').update({
        'status': withdrawal.status,
        'processed_at': withdrawal.processedAt.isNotEmpty
            ? withdrawal.processedAt
            : null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', withdrawal.id);
      _bus.notify(DbTables.withdrawals);
    } catch (_) {}
  }

  @override
  Future<void> insertLedgerEntries(List<LedgerEntryModel> entries) async {
    if (entries.isEmpty) return;
    final nowIso = DateTime.now().toIso8601String();
    try {
      final payload = entries
          .map((e) => {
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
              })
          .toList();
      await _client.from('ledger_entries').insert(payload);
      _bus.notify(DbTables.ledgerEntries);
    } catch (_) {}
  }
}
