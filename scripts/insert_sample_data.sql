-- ===========================
-- Sample Users
-- ===========================
INSERT INTO users(name, email, password, is_active)
VALUES
('Admin User', 'admin@example.com', 'hashedpassword1', true),
('Alex Johnson', 'alex@example.com', 'hashedpassword2', true),
('Josh Smith', 'josh@example.com', 'hashedpassword3', true);

-- ===========================
-- Sample Gold Prices
-- ===========================
INSERT INTO gold_prices(price, currency, unit, source, is_active)
VALUES
(5000.00, 'USD', 'gram', 'API', true),
(4600.00, 'EUR', 'gram', 'API', true),
(380000.00, 'INR', 'gram', 'API', true),
(4300.00, 'GBP', 'gram', 'API', true);

-- ===========================
-- Sample Investments
-- ===========================
INSERT INTO investments(user_id, amount, gold_amount, price_per_gram, currency, status)
VALUES
((SELECT id FROM users WHERE name='Alex Johnson'), 1000, 0.2, 5000, 'USD', 'completed'),
((SELECT id FROM users WHERE name='Josh Smith'), 2000, 0.45, 4600, 'EUR', 'completed'),
((SELECT id FROM users WHERE name='Admin User'), 500, 0.1, 5000, 'USD', 'pending');

-- ===========================
-- Sample Transactions
-- ===========================
INSERT INTO transactions(user_id, investment_id, type, amount, gold_amount, price_per_gram, currency, status)
VALUES
(
  (SELECT id FROM users WHERE name='Alex Johnson'),
  (SELECT id FROM investments WHERE user_id=(SELECT id FROM users WHERE name='Alex Johnson')),
  'buy', 1000, 0.2, 5000, 'USD', 'completed'
),
(
  (SELECT id FROM users WHERE name='Josh Smith'),
  (SELECT id FROM investments WHERE user_id=(SELECT id FROM users WHERE name='Josh Smith')),
  'buy', 2000, 0.45, 4600, 'EUR', 'completed'
),
(
  (SELECT id FROM users WHERE name='Admin User'),
  (SELECT id FROM investments WHERE user_id=(SELECT id FROM users WHERE name='Admin User')),
  'deposit', 500, NULL, NULL, 'USD', 'pending'
);
