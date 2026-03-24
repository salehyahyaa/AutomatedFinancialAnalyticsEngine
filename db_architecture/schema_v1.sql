-- Luminy database(db) version 1.0


CREATE TYPE account_status AS ENUM ('open', 'closed', 'frozen');
CREATE TYPE account_type AS ENUM ('debit', 'credit', 'not_fetched', 'depository');
CREATE TYPE charge_status AS ENUM ('pending', 'posted');
CREATE TYPE item_status AS ENUM ('active', 'inactive', 'error');
CREATE TYPE stock_trade_type AS ENUM ('buy', 'sell', 'dividend', 'transfer');

CREATE TABLE plaid_items (
  id SERIAL PRIMARY KEY,
  plaid_item_id VARCHAR(255) UNIQUE NOT NULL,
  bank VARCHAR(100),
  name VARCHAR(100),
  access_token VARCHAR(255),
  status item_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE accounts (
  id SERIAL PRIMARY KEY,
  plaid_item_id INTEGER NOT NULL,
  plaid_account_id VARCHAR(255) UNIQUE NOT NULL,
  bank VARCHAR(100),
  name VARCHAR(100),
  mask VARCHAR(4),
  account_type account_type DEFAULT 'not_fetched',
  current_balance NUMERIC(15,2),
  balance_owed NUMERIC(15,2),
  credit_limit NUMERIC(15,2),
  currency_code VARCHAR(3) DEFAULT 'USD',
  status account_status DEFAULT 'open',
  last_synced_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT accounts_plaid_item_account_unique UNIQUE (plaid_item_id, plaid_account_id),
  CONSTRAINT chk_credit_balance_owed CHECK (
    account_type <> 'credit' OR balance_owed IS NOT NULL
  ),
  CONSTRAINT chk_credit_limit CHECK (
    account_type <> 'credit' OR credit_limit IS NOT NULL
  ),
  FOREIGN KEY (plaid_item_id) REFERENCES plaid_items(id) ON DELETE CASCADE
);

CREATE TABLE account_transactions (
  id SERIAL PRIMARY KEY,
  account_id INTEGER NOT NULL,
  plaid_transaction_id VARCHAR(255) NOT NULL,
  amount NUMERIC(15,2) NOT NULL,
  date DATE NOT NULL,
  transaction_time TIME,
  merchant_name VARCHAR(255),
  category VARCHAR(100),
  status charge_status NOT NULL DEFAULT 'posted',
  iso_currency_code VARCHAR(3) DEFAULT 'USD',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT account_transactions_plaid_tx_unique UNIQUE (plaid_transaction_id),
  CONSTRAINT account_transactions_account_tx_unique UNIQUE (account_id, plaid_transaction_id),
  FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
);

CREATE TABLE daily_balances (
  id SERIAL PRIMARY KEY,
  account_id INTEGER NOT NULL,
  date DATE NOT NULL,
  balance NUMERIC(15,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT unique_account_day UNIQUE (account_id, date),
  FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
);

CREATE TABLE stock_accounts (
  id SERIAL PRIMARY KEY,
  account_id INTEGER UNIQUE NOT NULL,
  brokerage_name VARCHAR(100) NOT NULL,
  buying_power NUMERIC(15,2) DEFAULT 0.00,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
);

CREATE TABLE stock_transactions (
  id SERIAL PRIMARY KEY,
  stock_account_id INTEGER NOT NULL,
  symbol VARCHAR(10) NOT NULL,
  trade_type stock_trade_type NOT NULL,
  quantity NUMERIC(18,8),
  price_per_share NUMERIC(18,4),
  total_amount NUMERIC(15,2) NOT NULL,
  date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_stock_trade_logic CHECK (
    (
      trade_type IN ('buy','sell') AND quantity > 0 AND price_per_share > 0
    ) OR (
      trade_type = 'dividend' AND (quantity IS NULL OR quantity = 0) AND (price_per_share IS NULL OR price_per_share = 0)
    ) OR (
      trade_type = 'transfer'
    )
  ),
  FOREIGN KEY (stock_account_id) REFERENCES stock_accounts(id) ON DELETE CASCADE
);

CREATE INDEX idx_accounts_plaid_item ON accounts(plaid_item_id);
CREATE INDEX idx_transactions_account_date ON account_transactions(account_id, date);
CREATE INDEX idx_transactions_account_status ON account_transactions(account_id, status);
CREATE INDEX idx_daily_balances_account_date ON daily_balances(account_id, date);
CREATE INDEX idx_stock_symbol_date ON stock_transactions(symbol, date);

