class DbTables {
  const DbTables._();

  static const String users = 'users';
  static const String accounts = 'accounts';
  static const String loans = 'loans';
  static const String loanRepayments = 'loan_repayments';
  static const String loanApplications = 'loan_applications';
  static const String deposits = 'deposits';
  static const String depositTransactions = 'deposit_transactions';
  static const String withdrawals = 'withdrawals';
  static const String ledgerEntries = 'ledger_entries';
  static const String transactions = 'transactions';
  static const String notifications = 'notifications';
  static const String adminRequests = 'admin_requests';
  static const String pendingSyncQueue = 'pending_sync_queue';
  static const String loanProducts = 'loan_products';
  static const String transactionRequests = 'transaction_requests';
}

class DbColumns {
  const DbColumns._();

  static const String id = 'id';
  static const String userId = 'user_id';
  static const String accountId = 'account_id';
  static const String loanId = 'loan_id';
  static const String applicationId = 'application_id';
  static const String depositId = 'deposit_id';
  static const String withdrawalId = 'withdrawal_id';
  static const String fullName = 'full_name';
  static const String email = 'email';
  static const String phoneNumber = 'phone_number';
  static const String dateOfBirth = 'date_of_birth';
  static const String nationalId = 'national_id';
  static const String address = 'address';
  static const String photoUrl = 'photo_url';
  static const String customerId = 'customer_id';
  static const String kycStatus = 'kyc_status';
  static const String accountType = 'account_type';
  static const String balanceValue = 'balance_value';
  static const String isAdmin = 'is_admin';
  static const String fcmToken = 'fcm_token';
  static const String status = 'status';
  static const String amountValue = 'amount_value';
  static const String remainingBalanceValue = 'remaining_balance_value';
  static const String interestRateBps = 'interest_rate_bps';
  static const String period = 'period';
  static const String purpose = 'purpose';
  static const String nextPaymentDate = 'next_payment_date';
  static const String repaymentProgress = 'repayment_progress';
  static const String method = 'method';
  static const String reference = 'reference';
  static const String title = 'title';
  static const String subtitle = 'subtitle';
  static const String isCredit = 'is_credit';
  static const String message = 'message';
  static const String type = 'type';
  static const String isRead = 'is_read';
  static const String reviewedBy = 'reviewed_by';
  static const String reviewedAt = 'reviewed_at';
  static const String rejectionReason = 'rejection_reason';
  static const String entryType = 'entry_type';
  static const String referenceType = 'reference_type';
  static const String referenceId = 'reference_id';
  static const String requestType = 'request_type';
  static const String requestStatus = 'request_status';
  static const String operation = 'operation';
  static const String payloadJson = 'payload_json';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String isDeleted = 'is_deleted';
  static const String syncStatus = 'sync_status';
  static const String version = 'version';
}

class DbStatus {
  const DbStatus._();

  static const String pending = 'Pending';
  static const String approved = 'Approved';
  static const String rejected = 'Rejected';
  static const String active = 'Active';
  static const String completed = 'Completed';
  static const String failed = 'Failed';
  static const String paidOff = 'Paid Off';
  static const String none = 'None';
}

class DbSyncStatus {
  const DbSyncStatus._();

  static const String synced = 'synced';
  static const String pendingSync = 'pending_sync';
  static const String conflict = 'conflict';
}

class DbEntryType {
  const DbEntryType._();

  static const String debit = 'debit';
  static const String credit = 'credit';
}

class DbReferenceType {
  const DbReferenceType._();

  static const String loanDisbursement = 'loan_disbursement';
  static const String loanRepayment = 'loan_repayment';
  static const String deposit = 'deposit';
  static const String withdrawal = 'withdrawal';
  static const String adjustment = 'adjustment';
}

class DbOperations {
  const DbOperations._();

  static const String insert = 'insert';
  static const String update = 'update';
  static const String delete = 'delete';
}

class DbDefaults {
  const DbDefaults._();

  static const String accountStatus = 'Active';
  static const String currency = 'UGX';
  static const String depositMethod = 'Manual';
  static const String withdrawalMethod = 'Manual';
  static const String repaymentMethod = 'Mobile Money';
}

class DbRequestStatus {
  const DbRequestStatus._();

  static const String pending = 'pending';
  static const String completed = 'completed';
  static const String failed = 'failed';
}
