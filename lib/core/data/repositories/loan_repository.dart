import 'package:twezimbeapp/core/data/models/ledger_entry_model.dart';
import 'package:twezimbeapp/core/data/models/loan_application_model.dart';
import 'package:twezimbeapp/core/data/models/loan_model.dart';
import 'package:twezimbeapp/core/data/models/loan_product_model.dart';
import 'package:twezimbeapp/core/data/models/loan_repayment_model.dart';

/// Contract for loan persistence operations.
abstract class LoanRepository {
  /// Streams the latest active loan for a user.
  Stream<LoanModel?> watchActiveLoan(String userId);

  /// Streams loan applications for a user.
  Stream<List<LoanApplicationModel>> watchLoanApplications(
    String userId, {
    int limit = 100,
  });

  /// Fetches the most recent loan for a user.
  Future<LoanModel?> getLatestLoan(String userId);

  /// Inserts or updates a loan.
  Future<void> upsertLoan(LoanModel loan);

  /// Inserts or updates a loan application.
  Future<void> upsertLoanApplication(LoanApplicationModel application);

  /// Updates a loan application.
  Future<void> updateLoanApplication(LoanApplicationModel application);

  /// Fetches a loan application by id.
  Future<LoanApplicationModel?> getLoanApplication(String applicationId);

  /// Inserts a loan repayment.
  Future<void> insertLoanRepayment(LoanRepaymentModel repayment);

  /// Inserts ledger entries for double-entry bookkeeping.
  Future<void> insertLedgerEntries(List<LedgerEntryModel> entries);

  /// Returns cached loan products, refreshing if requested.
  Future<List<LoanProductModel>> getLoanProducts({bool refresh = false});

  /// Inserts or updates loan products in bulk.
  Future<void> upsertLoanProducts(List<LoanProductModel> products);
}
