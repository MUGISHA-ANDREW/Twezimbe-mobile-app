import 'package:twezimbeapp/core/data/models/ledger_entry_model.dart';
import 'package:twezimbeapp/core/data/models/withdrawal_model.dart';

/// Contract for withdrawal persistence operations.
abstract class WithdrawalRepository {
  /// Streams withdrawals for a user.
  Stream<List<WithdrawalModel>> watchWithdrawals(String userId, {int limit = 100});

  /// Inserts a withdrawal.
  Future<void> insertWithdrawal(WithdrawalModel withdrawal);

  /// Updates a withdrawal.
  Future<void> updateWithdrawal(WithdrawalModel withdrawal);

  /// Inserts ledger entries for double-entry bookkeeping.
  Future<void> insertLedgerEntries(List<LedgerEntryModel> entries);
}
