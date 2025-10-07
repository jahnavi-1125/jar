-- =====================================================
-- Gold Investment Platform
-- PostgreSQL Database Schema
-- Humanized version — written like a dev would
-- =====================================================

-- enable UUID generation
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------------------------------
-- ENUM types for statuses
-- -----------------------------------------------------
CREATE TYPE investment_status AS ENUM ('pending', 'completed', 'cancelled', 'failed');
CREATE TYPE transaction_type AS ENUM ('buy','sell','deposit','withdrawal');
CREATE TYPE transaction_status AS ENUM ('pending','completed','failed','refunded');

-- -----------------------------------------------------
-- USERS table
-- -----------------------------------------------------
-- Stores user info
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL CHECK (length(name) >= 2),
    email VARCHAR(255) NOT NULL UNIQUE CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    password VARCHAR(255) NOT NULL CHECK (length(password) >= 6),
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- some quick indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_active ON users(is_active);

-- -----------------------------------------------------
-- GOLD PRICES table
-- -----------------------------------------------------
-- Stores gold prices in different currencies and units
CREATE TABLE gold_prices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    currency VARCHAR(3) DEFAULT 'USD' NOT NULL,
    unit VARCHAR(10) DEFAULT 'gram' NOT NULL,
    source VARCHAR(50) DEFAULT 'API' NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_gold_currency ON gold_prices(currency);
CREATE INDEX idx_gold_active ON gold_prices(is_active);

-- -----------------------------------------------------
-- INVESTMENTS table
-- -----------------------------------------------------
-- User investments in gold
CREATE TABLE investments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    amount NUMERIC(12,2) NOT NULL CHECK(amount >= 0),
    gold_amount NUMERIC(10,4) NOT NULL CHECK(gold_amount >= 0),
    price_per_gram NUMERIC(10,2) NOT NULL CHECK(price_per_gram >= 0),
    currency VARCHAR(3) DEFAULT 'USD' NOT NULL,
    status investment_status DEFAULT 'pending',
    investment_date TIMESTAMP DEFAULT now(),
    notes TEXT NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    CONSTRAINT fk_invest_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE RESTRICT
);

CREATE INDEX idx_invest_user ON investments(user_id);
CREATE INDEX idx_invest_status ON investments(status);
CREATE INDEX idx_invest_date ON investments(investment_date);

-- -----------------------------------------------------
-- TRANSACTIONS table
-- -----------------------------------------------------
-- Tracks buy/sell/deposit/withdrawals
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    investment_id UUID NULL,
    type transaction_type NOT NULL,
    amount NUMERIC(12,2) NOT NULL CHECK(amount >= 0),
    gold_amount NUMERIC(10,4) NULL CHECK(gold_amount >= 0),
    price_per_gram NUMERIC(10,2) NULL CHECK(price_per_gram >= 0),
    currency VARCHAR(3) DEFAULT 'USD' NOT NULL,
    status transaction_status DEFAULT 'pending',
    transaction_date TIMESTAMP DEFAULT now(),
    reference VARCHAR(100) NULL,
    description TEXT NULL,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now(),
    CONSTRAINT fk_trans_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_trans_invest FOREIGN KEY(investment_id) REFERENCES investments(id) ON DELETE SET NULL
);

CREATE INDEX idx_trans_user ON transactions(user_id);
CREATE INDEX idx_trans_invest ON transactions(investment_id);
CREATE INDEX idx_trans_type ON transactions(type);
CREATE INDEX idx_trans_status ON transactions(status);
CREATE INDEX idx_trans_date ON transactions(transaction_date);

-- -----------------------------------------------------
-- TRIGGER for auto-updating updated_at
-- -----------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = now();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to all tables
DO $$
BEGIN
   -- users
   IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_update_users') THEN
       CREATE TRIGGER trg_update_users
       BEFORE UPDATE ON users
       FOR EACH ROW EXECUTE FUNCTION update_updated_at();
   END IF;

   -- gold_prices
   IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_update_gold_prices') THEN
       CREATE TRIGGER trg_update_gold_prices
       BEFORE UPDATE ON gold_prices
       FOR EACH ROW EXECUTE FUNCTION update_updated_at();
   END IF;

   -- investments
   IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_update_investments') THEN
       CREATE TRIGGER trg_update_investments
       BEFORE UPDATE ON investments
       FOR EACH ROW EXECUTE FUNCTION update_updated_at();
   END IF;

   -- transactions
   IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='trg_update_transactions') THEN
       CREATE TRIGGER trg_update_transactions
       BEFORE UPDATE ON transactions
       FOR EACH ROW EXECUTE FUNCTION update_updated_at();
   END IF;
END$$;

-- ========================= END OF SCHEMA =========================