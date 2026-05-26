import 'package:twezimbeapp/core/data/storage_config.dart';
import 'package:twezimbeapp/core/data/repositories/deposit_repository.dart';
import 'package:twezimbeapp/core/data/repositories/loan_repository.dart';
import 'package:twezimbeapp/core/data/repositories/withdrawal_repository.dart';
import 'package:twezimbeapp/core/data/repositories/sqlite_deposit_repository.dart';
import 'package:twezimbeapp/core/data/repositories/sqlite_loan_repository.dart';
import 'package:twezimbeapp/core/data/repositories/sqlite_withdrawal_repository.dart';

/// Provides repositories based on the configured storage backend.
class RepositoryRegistry {
  RepositoryRegistry._();

  static StorageConfig storage = StorageConfig.sqlite;

  static LoanRepository get loanRepository {
    switch (storage) {
      case StorageConfig.firestore:
        return _sqliteLoanRepository;
      case StorageConfig.sqlite:
        return _sqliteLoanRepository;
    }
  }

  static DepositRepository get depositRepository {
    switch (storage) {
      case StorageConfig.firestore:
        return _sqliteDepositRepository;
      case StorageConfig.sqlite:
        return _sqliteDepositRepository;
    }
  }

  static WithdrawalRepository get withdrawalRepository {
    switch (storage) {
      case StorageConfig.firestore:
        return _sqliteWithdrawalRepository;
      case StorageConfig.sqlite:
        return _sqliteWithdrawalRepository;
    }
  }

  static final SqliteLoanRepository _sqliteLoanRepository =
      SqliteLoanRepository();
  static final SqliteDepositRepository _sqliteDepositRepository =
      SqliteDepositRepository();
  static final SqliteWithdrawalRepository _sqliteWithdrawalRepository =
      SqliteWithdrawalRepository();
}
