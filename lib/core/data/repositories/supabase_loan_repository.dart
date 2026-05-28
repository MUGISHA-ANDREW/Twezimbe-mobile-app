import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twezimbeapp/core/data/change_bus.dart';
import 'package:twezimbeapp/core/data/db_constants.dart';
import 'package:twezimbeapp/core/data/models/ledger_entry_model.dart';
import 'package:twezimbeapp/core/data/models/loan_application_model.dart';
import 'package:twezimbeapp/core/data/models/loan_model.dart';
import 'package:twezimbeapp/core/data/models/loan_product_model.dart';
import 'package:twezimbeapp/core/data/models/loan_repayment_model.dart';
import 'package:twezimbeapp/core/data/repositories/loan_repository.dart';

class SupabaseLoanRepository implements LoanRepository {
  static SupabaseClient get _client => Supabase.instance.client;
  final DatabaseChangeBus _bus = DatabaseChangeBus.instance;
  final Map<String, List<LoanProductModel>> _loanProductsCache = {};

  static bool _isUuid(String id) => RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(id);

  @override
  Stream<LoanModel?> watchActiveLoan(String userId) {
    final controller = StreamController<LoanModel?>.broadcast();
    StreamSubscription<String>? sub;

    Future<void> emit() async {
      try {
        final rows = await _client
            .from('loans')
            .select()
            .eq('user_id', userId)
            .eq('status', DbStatus.active)
            .order('updated_at', ascending: false)
            .limit(1);
        controller.add(rows.isEmpty ? null : LoanModel.fromMap(rows.first));
      } catch (_) {
        controller.add(null);
      }
    }

    controller.onListen = () {
      unawaited(emit());
      sub = _bus.stream
          .where((t) => t == DbTables.loans)
          .listen((_) => unawaited(emit()));
    };
    controller.onCancel = () async => sub?.cancel();
    return controller.stream;
  }

  @override
  Stream<List<LoanApplicationModel>> watchLoanApplications(
    String userId, {
    int limit = 100,
  }) {
    final controller =
        StreamController<List<LoanApplicationModel>>.broadcast();
    StreamSubscription<String>? sub;

    Future<void> emit() async {
      try {
        final rows = await _client
            .from('loan_applications')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(limit);
        controller.add(rows.map(LoanApplicationModel.fromMap).toList());
      } catch (_) {
        controller.add([]);
      }
    }

    controller.onListen = () {
      unawaited(emit());
      sub = _bus.stream
          .where((t) => t == DbTables.loanApplications)
          .listen((_) => unawaited(emit()));
    };
    controller.onCancel = () async => sub?.cancel();
    return controller.stream;
  }

  @override
  Future<LoanModel?> getLatestLoan(String userId) async {
    try {
      final rows = await _client
          .from('loans')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(1);
      return rows.isEmpty ? null : LoanModel.fromMap(rows.first);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> upsertLoan(LoanModel loan) async {
    final nowIso = DateTime.now().toIso8601String();
    final data = <String, dynamic>{
      'user_id': loan.userId,
      'loan_id': loan.loanId,
      'loan_type': loan.type,
      'status': loan.status,
      'amount_value': loan.amountValue,
      'remaining_balance_value': loan.remainingBalanceValue,
      'period': loan.period,
      'purpose': loan.purpose,
      'next_payment_date': loan.nextPaymentDate,
      'repayment_progress': loan.repaymentProgress,
      'updated_at': nowIso,
      'sync_status': DbSyncStatus.synced,
    };

    if (_isUuid(loan.id)) {
      data['version'] = loan.version + 1;
      await _client.from('loans').update(data).eq('id', loan.id);
    } else {
      // No UUID — check for existing loan for this user
      final existing = await _client
          .from('loans')
          .select('id, version')
          .eq('user_id', loan.userId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (existing != null) {
        data['version'] =
            ((existing['version'] as num?)?.toInt() ?? 0) + 1;
        await _client.from('loans').update(data).eq('id', existing['id']);
      } else {
        data['created_at'] =
            loan.createdAt.isNotEmpty ? loan.createdAt : nowIso;
        data['version'] = 0;
        await _client.from('loans').insert(data);
      }
    }
    _bus.notify(DbTables.loans);
  }

  @override
  Future<void> upsertLoanApplication(LoanApplicationModel application) async {
    final nowIso = DateTime.now().toIso8601String();
    final data = <String, dynamic>{
      'application_id': application.applicationId,
      'user_id': application.userId,
      'user_name': application.userName,
      'user_email': application.userEmail,
      'user_phone': application.userPhone,
      'customer_id': application.customerId,
      'loan_type': application.loanType,
      'amount_value': application.amountValue,
      'period': application.period,
      'purpose': application.purpose,
      'status': application.status,
      'rejection_reason': application.rejectionReason,
      'reviewed_by': application.reviewedBy,
      'reviewed_at': application.reviewedAt.isNotEmpty
          ? application.reviewedAt
          : null,
      'updated_at': nowIso,
      'sync_status': DbSyncStatus.synced,
      'version': application.version,
    };

    // Find existing by application_id or uuid
    final existing = await _client
        .from('loan_applications')
        .select('id')
        .eq('application_id', application.applicationId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('loan_applications')
          .update(data)
          .eq('id', existing['id']);
    } else if (_isUuid(application.id)) {
      await _client
          .from('loan_applications')
          .update(data)
          .eq('id', application.id);
    } else {
      data['created_at'] =
          application.createdAt.isNotEmpty ? application.createdAt : nowIso;
      await _client.from('loan_applications').insert(data);
    }
    _bus.notify(DbTables.loanApplications);
  }

  @override
  Future<void> updateLoanApplication(LoanApplicationModel application) async {
    await upsertLoanApplication(application);
  }

  @override
  Future<LoanApplicationModel?> getLoanApplication(
    String applicationId,
  ) async {
    try {
      final rows = await _client
          .from('loan_applications')
          .select()
          .or('application_id.eq.$applicationId,id.eq.$applicationId')
          .limit(1);
      return rows.isEmpty ? null : LoanApplicationModel.fromMap(rows.first);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> insertLoanRepayment(LoanRepaymentModel repayment) async {
    final nowIso = DateTime.now().toIso8601String();
    try {
      await _client.from('loan_repayments').insert({
        'loan_id': _isUuid(repayment.loanId) ? repayment.loanId : null,
        'user_id': repayment.userId,
        'amount_value': repayment.amountValue,
        'method': repayment.method,
        'status': repayment.status,
        'paid_at': repayment.paidAt.isNotEmpty ? repayment.paidAt : null,
        'created_at': repayment.createdAt.isNotEmpty ? repayment.createdAt : nowIso,
        'updated_at': repayment.updatedAt.isNotEmpty ? repayment.updatedAt : nowIso,
        'sync_status': DbSyncStatus.synced,
        'version': 0,
      });
      _bus.notify(DbTables.loanRepayments);
    } catch (_) {
      // Ignore if foreign key fails (loan_id not UUID)
    }
  }

  @override
  Future<void> insertLedgerEntries(List<LedgerEntryModel> entries) async {
    if (entries.isEmpty) return;
    final nowIso = DateTime.now().toIso8601String();
    try {
      final payload = entries
          .map((e) => {
                'user_id': e.userId,
                'account_id': (e.accountId != null && _isUuid(e.accountId!))
                    ? e.accountId
                    : null,
                'amount_value': e.amountValue,
                'entry_type': e.entryType,
                'reference_type': e.referenceType,
                'reference_id': e.referenceId,
                'created_at':
                    e.createdAt.isNotEmpty ? e.createdAt : nowIso,
                'updated_at':
                    e.updatedAt.isNotEmpty ? e.updatedAt : nowIso,
                'sync_status': DbSyncStatus.synced,
                'version': 0,
              })
          .toList();
      await _client.from('ledger_entries').insert(payload);
      _bus.notify(DbTables.ledgerEntries);
    } catch (_) {}
  }

  @override
  Future<List<LoanProductModel>> getLoanProducts({
    bool refresh = false,
  }) async {
    if (!refresh && _loanProductsCache.containsKey('all')) {
      return _loanProductsCache['all']!;
    }
    try {
      final rows = await _client
          .from('loan_products')
          .select()
          .order('name', ascending: true);
      final products = rows.map(LoanProductModel.fromMap).toList();
      _loanProductsCache['all'] = products;
      return products;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> upsertLoanProducts(List<LoanProductModel> products) async {
    if (products.isEmpty) return;
    try {
      final payload = products
          .map((p) => {
                'name': p.name,
                'interest_rate_bps': p.interestRateBps,
                'min_amount_value': p.minAmountValue,
                'max_amount_value': p.maxAmountValue,
                'updated_at': DateTime.now().toIso8601String(),
                'sync_status': DbSyncStatus.synced,
              })
          .toList();
      await _client.from('loan_products').upsert(payload);
      _loanProductsCache.remove('all');
    } catch (_) {}
  }
}
