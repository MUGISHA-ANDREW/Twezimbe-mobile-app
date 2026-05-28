-- Twezimbe Supabase Database Schema
-- Run this in your Supabase SQL Editor (fresh install or after DROP TABLE cascade)

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE public.users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  full_name TEXT,
  email TEXT UNIQUE,
  phone_number TEXT,
  date_of_birth TEXT,
  national_id TEXT,
  address TEXT,
  photo_url TEXT,
  customer_id TEXT UNIQUE,
  kyc_status TEXT DEFAULT 'Pending',
  account_type TEXT DEFAULT 'Savings Account',
  balance_value BIGINT DEFAULT 0 CHECK (balance_value >= 0),
  is_admin BOOLEAN DEFAULT FALSE,
  fcm_token TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  sync_status TEXT DEFAULT 'synced',
  version INTEGER DEFAULT 0
);

-- Accounts table
CREATE TABLE public.accounts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) NOT NULL,
  account_type TEXT NOT NULL,
  balance_value BIGINT DEFAULT 0 CHECK (balance_value >= 0),
  status TEXT NOT NULL,
  currency TEXT DEFAULT 'UGX',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  sync_status TEXT DEFAULT 'synced',
  version INTEGER DEFAULT 0
);

-- Loans table
CREATE TABLE public.loans (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) NOT NULL,
  account_id UUID REFERENCES public.accounts(id),
  loan_id TEXT,
  loan_type TEXT,
  status TEXT NOT NULL,
  amount_value BIGINT DEFAULT 0 CHECK (amount_value >= 0),
  remaining_balance_value BIGINT DEFAULT 0 CHECK (remaining_balance_value >= 0),
  interest_rate_bps INTEGER DEFAULT 0,
  period TEXT,
  purpose TEXT,
  next_payment_date TEXT,
  repayment_progress INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  sync_status TEXT DEFAULT 'synced',
  version INTEGER DEFAULT 0
);

-- Loan Applications table
CREATE TABLE public.loan_applications (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  application_id TEXT UNIQUE,
  user_id UUID REFERENCES public.users(id) NOT NULL,
  user_name TEXT,
  user_email TEXT,
  user_phone TEXT,
  customer_id TEXT,
  loan_type TEXT,
  amount_value BIGINT DEFAULT 0 CHECK (amount_value >= 0),
  period TEXT,
  purpose TEXT,
  status TEXT NOT NULL,
  rejection_reason TEXT,
  reviewed_by TEXT,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  sync_status TEXT DEFAULT 'synced',
  version INTEGER DEFAULT 0
);

-- Loan Repayments table
CREATE TABLE public.loan_repayments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  loan_id UUID REFERENCES public.loans(id),
  user_id UUID REFERENCES public.users(id) NOT NULL,
  amount_value BIGINT NOT NULL CHECK (amount_value > 0),
  method TEXT,
  status TEXT NOT NULL,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  sync_status TEXT DEFAULT 'synced',
  version INTEGER DEFAULT 0
);

-- Deposits table
CREATE TABLE public.deposits (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) NOT NULL,
  account_id UUID REFERENCES public.accounts(id),
  amount_value BIGINT NOT NULL CHECK (amount_value > 0),
  method TEXT,
  status TEXT NOT NULL,
  reference TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  sync_status TEXT DEFAULT 'synced',
  version INTEGER DEFAULT 0
);

-- Withdrawals table
CREATE TABLE public.withdrawals (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) NOT NULL,
  account_id UUID REFERENCES public.accounts(id),
  amount_value BIGINT NOT NULL CHECK (amount_value > 0),
  method TEXT,
  status TEXT NOT NULL,
  requested_at TIMESTAMPTZ,
  processed_at TIMESTAMPTZ,
  reference TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  sync_status TEXT DEFAULT 'synced',
  version INTEGER DEFAULT 0
);

-- Ledger Entries table
CREATE TABLE public.ledger_entries (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) NOT NULL,
  account_id UUID REFERENCES public.accounts(id),
  amount_value BIGINT NOT NULL CHECK (amount_value > 0),
  entry_type TEXT NOT NULL CHECK (entry_type IN ('debit', 'credit')),
  reference_type TEXT NOT NULL,
  reference_id TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  sync_status TEXT DEFAULT 'synced',
  version INTEGER DEFAULT 0
);

-- Transactions table
CREATE TABLE public.transactions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) NOT NULL,
  title TEXT,
  subtitle TEXT,
  amount_value BIGINT NOT NULL CHECK (amount_value >= 0),
  is_credit BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  sync_status TEXT DEFAULT 'synced',
  version INTEGER DEFAULT 0
);

-- Notifications table
CREATE TABLE public.notifications (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) NOT NULL,
  title TEXT,
  message TEXT,
  type TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  sync_status TEXT DEFAULT 'synced',
  version INTEGER DEFAULT 0
);

-- Admin Requests table
CREATE TABLE public.admin_requests (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  request_id TEXT,
  type TEXT,
  user_id UUID REFERENCES public.users(id),
  user_name TEXT,
  user_email TEXT,
  status TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  sync_status TEXT DEFAULT 'synced',
  version INTEGER DEFAULT 0
);

-- Transaction Requests table
CREATE TABLE public.transaction_requests (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) NOT NULL,
  request_type TEXT NOT NULL,
  amount_value BIGINT DEFAULT 0 CHECK (amount_value >= 0),
  reference_id TEXT,
  request_status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Loan Products table
CREATE TABLE public.loan_products (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  interest_rate_bps INTEGER DEFAULT 0,
  min_amount_value BIGINT DEFAULT 0,
  max_amount_value BIGINT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  sync_status TEXT DEFAULT 'synced',
  version INTEGER DEFAULT 0
);

-- Indexes
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_accounts_user ON public.accounts(user_id);
CREATE INDEX idx_loans_user_status ON public.loans(user_id, status);
CREATE INDEX idx_loans_user_created ON public.loans(user_id, created_at DESC);
CREATE INDEX idx_loan_app_user_status ON public.loan_applications(user_id, status);
CREATE INDEX idx_loan_app_user_created ON public.loan_applications(user_id, created_at DESC);
CREATE INDEX idx_loan_rep_loan ON public.loan_repayments(loan_id);
CREATE INDEX idx_deposits_user_status ON public.deposits(user_id, status);
CREATE INDEX idx_deposits_user_created ON public.deposits(user_id, created_at DESC);
CREATE INDEX idx_withdrawals_user_status ON public.withdrawals(user_id, status);
CREATE INDEX idx_withdrawals_user_created ON public.withdrawals(user_id, created_at DESC);
CREATE INDEX idx_transactions_user_created ON public.transactions(user_id, created_at DESC);
CREATE INDEX idx_notifications_user_created ON public.notifications(user_id, created_at DESC);
CREATE INDEX idx_ledger_user_created ON public.ledger_entries(user_id, created_at DESC);
CREATE INDEX idx_request_user_created ON public.transaction_requests(user_id, created_at DESC);

-- Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loan_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loan_repayments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deposits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.withdrawals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaction_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loan_products ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS POLICIES — users table
-- ============================================================================
CREATE POLICY "users_own_select" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_own_insert" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "users_own_update" ON public.users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "users_admin_all" ON public.users
  FOR ALL
  USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE))
  WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE));

-- ============================================================================
-- RLS POLICIES — accounts table
-- ============================================================================
CREATE POLICY "accounts_own_select" ON public.accounts
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "accounts_own_insert" ON public.accounts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "accounts_own_update" ON public.accounts
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "accounts_admin_all" ON public.accounts
  FOR ALL
  USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE))
  WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE));

-- ============================================================================
-- RLS POLICIES — loans table
-- ============================================================================
CREATE POLICY "loans_own_select" ON public.loans
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "loans_own_insert" ON public.loans
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "loans_own_update" ON public.loans
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "loans_admin_all" ON public.loans
  FOR ALL
  USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE))
  WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE));

-- ============================================================================
-- RLS POLICIES — loan_applications table
-- ============================================================================
CREATE POLICY "loan_apps_own_select" ON public.loan_applications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "loan_apps_own_insert" ON public.loan_applications
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "loan_apps_own_update" ON public.loan_applications
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "loan_apps_admin_all" ON public.loan_applications
  FOR ALL
  USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE))
  WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE));

-- ============================================================================
-- RLS POLICIES — loan_repayments table
-- ============================================================================
CREATE POLICY "loan_repayments_own_select" ON public.loan_repayments
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "loan_repayments_own_insert" ON public.loan_repayments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "loan_repayments_admin_all" ON public.loan_repayments
  FOR ALL
  USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE))
  WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE));

-- ============================================================================
-- RLS POLICIES — deposits table
-- ============================================================================
CREATE POLICY "deposits_own_select" ON public.deposits
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "deposits_own_insert" ON public.deposits
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "deposits_admin_all" ON public.deposits
  FOR ALL
  USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE))
  WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE));

-- ============================================================================
-- RLS POLICIES — withdrawals table
-- ============================================================================
CREATE POLICY "withdrawals_own_select" ON public.withdrawals
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "withdrawals_own_insert" ON public.withdrawals
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "withdrawals_admin_all" ON public.withdrawals
  FOR ALL
  USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE))
  WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE));

-- ============================================================================
-- RLS POLICIES — ledger_entries table
-- ============================================================================
CREATE POLICY "ledger_own_select" ON public.ledger_entries
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "ledger_own_insert" ON public.ledger_entries
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "ledger_admin_all" ON public.ledger_entries
  FOR ALL
  USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE))
  WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE));

-- ============================================================================
-- RLS POLICIES — transactions table
-- ============================================================================
CREATE POLICY "transactions_own_select" ON public.transactions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "transactions_own_insert" ON public.transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "transactions_admin_all" ON public.transactions
  FOR ALL
  USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE))
  WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE));

-- ============================================================================
-- RLS POLICIES — notifications table
-- ============================================================================
CREATE POLICY "notifications_own_select" ON public.notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "notifications_own_update" ON public.notifications
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "notifications_own_insert" ON public.notifications
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "notifications_admin_all" ON public.notifications
  FOR ALL
  USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE))
  WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE));

-- ============================================================================
-- RLS POLICIES — admin_requests table
-- ============================================================================
CREATE POLICY "admin_requests_admin_all" ON public.admin_requests
  FOR ALL
  USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE))
  WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE));

-- ============================================================================
-- RLS POLICIES — transaction_requests table
-- ============================================================================
CREATE POLICY "txreq_own_all" ON public.transaction_requests
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "txreq_admin_all" ON public.transaction_requests
  FOR ALL
  USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE))
  WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE));

-- ============================================================================
-- RLS POLICIES — loan_products table (read-only for all authenticated users)
-- ============================================================================
CREATE POLICY "loan_products_read" ON public.loan_products
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "loan_products_admin_all" ON public.loan_products
  FOR ALL
  USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE))
  WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND is_admin = TRUE));

-- ============================================================================
-- Functions and Triggers
-- ============================================================================

-- Auto-create user profile row on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, customer_id, is_admin, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    'CUST-' || LPAD(FLOOR(RANDOM() * 100000)::TEXT, 5, '0'),
    LOWER(COALESCE(NEW.email, '')) = 'admin@twezimbe.co.ug',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.accounts FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.loans FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.loan_applications FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.loan_repayments FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.deposits FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.withdrawals FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.ledger_entries FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.transactions FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.admin_requests FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.transaction_requests FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.loan_products FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
