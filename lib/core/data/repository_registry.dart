import 'package:twezimbeapp/core/data/storage_config.dart';
import 'package:twezimbeapp/core/data/repositories/deposit_repository.dart';
import 'package:twezimbeapp/core/data/repositories/loan_repository.dart';
import 'package:twezimbeapp/core/data/repositories/withdrawal_repository.dart';
import 'package:twezimbeapp/core/data/repositories/supabase_deposit_repository.dart';
import 'package:twezimbeapp/core/data/repositories/supabase_loan_repository.dart';
import 'package:twezimbeapp/core/data/repositories/supabase_withdrawal_repository.dart';

/// Provides repositories based on the configured storage backend.
class RepositoryRegistry {
  RepositoryRegistry._();

  static StorageConfig storage = StorageConfig.supabase;

  static LoanRepository get loanRepository => _supabaseLoanRepository;
  static DepositRepository get depositRepository => _supabaseDepositRepository;
  static WithdrawalRepository get withdrawalRepository =>
      _supabaseWithdrawalRepository;

  static final SupabaseLoanRepository _supabaseLoanRepository =
      SupabaseLoanRepository();
  static final SupabaseDepositRepository _supabaseDepositRepository =
      SupabaseDepositRepository();
  static final SupabaseWithdrawalRepository _supabaseWithdrawalRepository =
      SupabaseWithdrawalRepository();
}
