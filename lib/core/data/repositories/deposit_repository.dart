import 'package:twezimbeapp/core/data/models/deposit_model.dart';
import 'package:twezimbeapp/core/data/models/deposit_transaction_model.dart';
import 'package:twezimbeapp/core/data/models/ledger_entry_model.dart';

/// Contract for deposit persistence operations.
abstract class DepositRepository {
  /// Streams deposits for a user.
  Stream<List<DepositModel>> watchDeposits(String userId, {int limit = 100});

  /// Inserts a deposit.
  Future<void> insertDeposit(DepositModel deposit);

  /// Inserts deposit transactions.
  Future<void> insertDepositTransactions(List<DepositTransactionModel> items);

  /// Inserts ledger entries for double-entry bookkeeping.
  Future<void> insertLedgerEntries(List<LedgerEntryModel> entries);
}
