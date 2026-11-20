package migrations

import (
	"database/sql"
	"fmt"
	"log"
	"time"
)

const CurrentSchemaVersion = 1

const SchemaV1 = `
-- Schema Version Tracking
CREATE TABLE IF NOT EXISTS schema_version (
    version INTEGER PRIMARY KEY,
    applied_at TEXT NOT NULL
);

-- App Settings (Key-Value)
CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Financial Accounts / Wallets
CREATE TABLE IF NOT EXISTS accounts (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- CASH, BANK, EWALLET
    balance INTEGER NOT NULL DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'IDR',
    color TEXT NOT NULL DEFAULT '#007AFF',
    icon TEXT NOT NULL DEFAULT 'creditcard.fill',
    is_archived INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_accounts_deleted ON accounts(deleted_at);

-- Categories
CREATE TABLE IF NOT EXISTS categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- INCOME, EXPENSE
    icon TEXT NOT NULL,
    color TEXT NOT NULL,
    is_default INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_categories_type ON categories(type);

-- Transactions
CREATE TABLE IF NOT EXISTS transactions (
    id TEXT PRIMARY KEY,
    account_id TEXT NOT NULL,
    to_account_id TEXT,
    category_id TEXT,
    amount INTEGER NOT NULL,
    type TEXT NOT NULL, -- INCOME, EXPENSE, TRANSFER
    note TEXT,
    transaction_date TEXT NOT NULL,
    receipt_path TEXT,
    recurring_rule_id TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT,
    FOREIGN KEY(account_id) REFERENCES accounts(id) ON DELETE RESTRICT,
    FOREIGN KEY(to_account_id) REFERENCES accounts(id) ON DELETE RESTRICT,
    FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_transactions_account ON transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_transactions_deleted ON transactions(deleted_at);

-- Recurring Rules
CREATE TABLE IF NOT EXISTS recurring_rules (
    id TEXT PRIMARY KEY,
    frequency TEXT NOT NULL, -- DAILY, WEEKLY, MONTHLY
    interval INTEGER NOT NULL DEFAULT 1,
    start_date TEXT NOT NULL,
    end_date TEXT,
    next_run_date TEXT NOT NULL,
    is_active INTEGER NOT NULL DEFAULT 1,
    template_json TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Budgets
CREATE TABLE IF NOT EXISTS budgets (
    id TEXT PRIMARY KEY,
    category_id TEXT NOT NULL,
    amount INTEGER NOT NULL,
    period TEXT NOT NULL DEFAULT 'MONTHLY',
    start_date TEXT NOT NULL,
    alert_threshold REAL NOT NULL DEFAULT 0.8,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_budgets_category ON budgets(category_id, period);

-- Savings Piggy Banks
CREATE TABLE IF NOT EXISTS savings (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    target_amount INTEGER NOT NULL,
    current_amount INTEGER NOT NULL DEFAULT 0,
    deadline TEXT NOT NULL,
    icon TEXT NOT NULL DEFAULT 'gift.fill',
    color TEXT NOT NULL DEFAULT '#FF9500',
    status TEXT NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, COMPLETED
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Savings Entries (Deposit / Withdraw)
CREATE TABLE IF NOT EXISTS savings_entries (
    id TEXT PRIMARY KEY,
    savings_id TEXT NOT NULL,
    account_id TEXT,
    amount INTEGER NOT NULL,
    type TEXT NOT NULL, -- DEPOSIT, WITHDRAW
    note TEXT,
    entry_date TEXT NOT NULL,
    created_at TEXT NOT NULL,
    FOREIGN KEY(savings_id) REFERENCES savings(id) ON DELETE CASCADE,
    FOREIGN KEY(account_id) REFERENCES accounts(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_savings_entries_savings ON savings_entries(savings_id);

-- Goals
CREATE TABLE IF NOT EXISTS goals (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    category TEXT NOT NULL, -- CAREER, HEALTH, LEARNING, FINANCE, PERSONAL
    deadline TEXT NOT NULL,
    priority TEXT NOT NULL DEFAULT 'MEDIUM',
    status TEXT NOT NULL DEFAULT 'ACTIVE',
    progress REAL NOT NULL DEFAULT 0.0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Goal Tasks / Milestones
CREATE TABLE IF NOT EXISTS goal_tasks (
    id TEXT PRIMARY KEY,
    goal_id TEXT NOT NULL,
    title TEXT NOT NULL,
    is_completed INTEGER NOT NULL DEFAULT 0,
    order_index INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY(goal_id) REFERENCES goals(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_goal_tasks_goal ON goal_tasks(goal_id);

-- Habits
CREATE TABLE IF NOT EXISTS habits (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    frequency TEXT NOT NULL DEFAULT 'DAILY',
    streak_current INTEGER NOT NULL DEFAULT 0,
    streak_longest INTEGER NOT NULL DEFAULT 0,
    icon TEXT NOT NULL DEFAULT 'flame.fill',
    color TEXT NOT NULL DEFAULT '#FF3B30',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

-- Habit Logs
CREATE TABLE IF NOT EXISTS habit_logs (
    id TEXT PRIMARY KEY,
    habit_id TEXT NOT NULL,
    logged_date TEXT NOT NULL, -- YYYY-MM-DD
    status INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    FOREIGN KEY(habit_id) REFERENCES habits(id) ON DELETE CASCADE
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_habit_logs_unique ON habit_logs(habit_id, logged_date);

-- Calendar Events
CREATE TABLE IF NOT EXISTS events (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    location TEXT,
    color TEXT NOT NULL DEFAULT '#5856D6',
    recurrence TEXT NOT NULL DEFAULT 'NONE',
    reminder_minutes INTEGER NOT NULL DEFAULT 15,
    is_completed INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_events_start ON events(start_time);

-- Notes & Journal
CREATE TABLE IF NOT EXISTS notes (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    mood TEXT,
    is_pinned INTEGER NOT NULL DEFAULT 0,
    is_archived INTEGER NOT NULL DEFAULT 0,
    note_date TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    deleted_at TEXT
);
CREATE INDEX IF NOT EXISTS idx_notes_date ON notes(note_date);
CREATE INDEX IF NOT EXISTS idx_notes_deleted ON notes(deleted_at);

-- Tags
CREATE TABLE IF NOT EXISTS tags (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    color TEXT NOT NULL DEFAULT '#007AFF'
);

-- Note Tags (Many-to-Many)
CREATE TABLE IF NOT EXISTS note_tags (
    note_id TEXT NOT NULL,
    tag_id TEXT NOT NULL,
    PRIMARY KEY(note_id, tag_id),
    FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE,
    FOREIGN KEY(tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

-- Full-Text Search (FTS5) for Notes
CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5(
    note_id UNINDEXED,
    title,
    content
);

-- Triggers for FTS5 synchronization
CREATE TRIGGER IF NOT EXISTS trg_notes_ai AFTER INSERT ON notes BEGIN
    INSERT INTO notes_fts(note_id, title, content) VALUES (new.id, new.title, new.content);
END;

CREATE TRIGGER IF NOT EXISTS trg_notes_ad AFTER DELETE ON notes BEGIN
    DELETE FROM notes_fts WHERE note_id = old.id;
END;

CREATE TRIGGER IF NOT EXISTS trg_notes_au AFTER UPDATE ON notes BEGIN
    DELETE FROM notes_fts WHERE note_id = old.id;
    INSERT INTO notes_fts(note_id, title, content) VALUES (new.id, new.title, new.content);
END;
`

// SeedDefaultData inserts starter categories, accounts, and settings if not present
func SeedDefaultData(db *sql.DB) error {
	now := time.Now().UTC().Format(time.RFC3339)

	// Check if already seeded
	var count int
	err := db.QueryRow("SELECT COUNT(*) FROM categories").Scan(&count)
	if err != nil {
		return err
	}
	if count > 0 {
		return nil // already seeded
	}

	tx, err := db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// Default Settings
	settings := map[string]string{
		"currency":         "IDR",
		"currency_symbol":  "Rp",
		"language":         "id",
		"theme":            "auto",
		"accent_color":     "indigo",
		"biometric_locked": "false",
		"first_launch":     "true",
	}
	for k, v := range settings {
		_, err = tx.Exec("INSERT OR IGNORE INTO settings(key, value, updated_at) VALUES(?, ?, ?)", k, v, now)
		if err != nil {
			return err
		}
	}

	// Default Accounts
	accounts := []struct {
		ID, Name, Type, Color, Icon string
		Balance                      int64
	}{
		{"acc-cash", "Uang Tunai (Dompet)", "CASH", "#34C759", "banknotes.fill", 500000},
		{"acc-bank", "BCA / Rekening Utama", "BANK", "#007AFF", "building.columns.fill", 5000000},
		{"acc-ewallet", "GoPay / OVO", "EWALLET", "#AF52DE", "creditcard.fill", 250000},
	}
	for _, a := range accounts {
		_, err = tx.Exec(
			"INSERT INTO accounts (id, name, type, balance, currency, color, icon, is_archived, created_at, updated_at) VALUES (?, ?, ?, ?, 'IDR', ?, ?, 0, ?, ?)",
			a.ID, a.Name, a.Type, a.Balance, a.Color, a.Icon, now, now,
		)
		if err != nil {
			return err
		}
	}

	// Default Categories
	categories := []struct {
		ID, Name, Type, Icon, Color string
	}{
		// Income
		{"cat-inc-1", "Gaji Pokok", "INCOME", "briefcase.fill", "#34C759"},
		{"cat-inc-2", "Bisnis & Freelance", "INCOME", "laptopcomputer", "#30B0C7"},
		{"cat-inc-3", "Investasi / Bunga", "INCOME", "chart.line.uptrend.xyaxis", "#5856D6"},
		{"cat-inc-4", "Hadiah / Bonus", "INCOME", "gift.fill", "#AF52DE"},
		{"cat-inc-5", "Pemasukan Lain", "INCOME", "ellipsis.circle.fill", "#8E8E93"},
		// Expense
		{"cat-exp-1", "Makanan & Minuman", "EXPENSE", "fork.knife", "#FF9500"},
		{"cat-exp-2", "Belanja Kebutuhan", "EXPENSE", "bag.fill", "#FF2D55"},
		{"cat-exp-3", "Transportasi & Bensin", "EXPENSE", "car.fill", "#007AFF"},
		{"cat-exp-4", "Tagihan, Listrik & Wifi", "EXPENSE", "bolt.fill", "#5856D6"},
		{"cat-exp-5", "Hiburan & Rekreasi", "EXPENSE", "film.fill", "#AF52DE"},
		{"cat-exp-6", "Kesehatan & Obat", "EXPENSE", "heart.fill", "#FF3B30"},
		{"cat-exp-7", "Pendidikan & Buku", "EXPENSE", "book.fill", "#32ADE6"},
		{"cat-exp-8", "Pengeluaran Lain", "EXPENSE", "ellipsis.circle.fill", "#8E8E93"},
	}
	for _, c := range categories {
		_, err = tx.Exec(
			"INSERT INTO categories (id, name, type, icon, color, is_default, created_at, updated_at) VALUES (?, ?, ?, ?, ?, 1, ?, ?)",
			c.ID, c.Name, c.Type, c.Icon, c.Color, now, now,
		)
		if err != nil {
			return err
		}
	}

	// Default Savings Piggy Bank
	_, err = tx.Exec(
		"INSERT INTO savings (id, name, target_amount, current_amount, deadline, icon, color, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, 'ACTIVE', ?, ?)",
		"sav-dana-darurat", "Dana Darurat", 15000000, 3000000, time.Now().AddDate(0, 6, 0).Format(time.RFC3339), "shield.checkerboard", "#34C759", now, now,
	)
	if err != nil {
		return err
	}

	// Default Habit
	_, err = tx.Exec(
		"INSERT INTO habits (id, title, frequency, streak_current, streak_longest, icon, color, created_at, updated_at) VALUES (?, ?, 'DAILY', 3, 7, 'drop.fill', '#007AFF', ?, ?)",
		"hab-water", "Minum Air 2 Liter", now, now,
	)
	if err != nil {
		return err
	}

	return tx.Commit()
}

// RunMigrations checks schema version and applies migrations safely
func RunMigrations(db *sql.DB) error {
	// Enable WAL mode & foreign keys
	if _, err := db.Exec("PRAGMA journal_mode = WAL;"); err != nil {
		return fmt.Errorf("failed to set WAL: %w", err)
	}
	if _, err := db.Exec("PRAGMA foreign_keys = ON;"); err != nil {
		return fmt.Errorf("failed to enable foreign keys: %w", err)
	}

	// Create schema_version table if not exists
	_, err := db.Exec(`CREATE TABLE IF NOT EXISTS schema_version (
		version INTEGER PRIMARY KEY,
		applied_at TEXT NOT NULL
	);`)
	if err != nil {
		return fmt.Errorf("failed to create schema_version: %w", err)
	}

	var currentVer int
	row := db.QueryRow("SELECT COALESCE(MAX(version), 0) FROM schema_version")
	if err := row.Scan(&currentVer); err != nil {
		return fmt.Errorf("failed to read schema version: %w", err)
	}

	log.Printf("[Migration] Current DB schema version: %d", currentVer)

	if currentVer < 1 {
		log.Println("[Migration] Applying V1 migration...")
		if _, err := db.Exec(SchemaV1); err != nil {
			return fmt.Errorf("failed to apply V1 schema: %w", err)
		}

		now := time.Now().UTC().Format(time.RFC3339)
		if _, err := db.Exec("INSERT INTO schema_version (version, applied_at) VALUES (1, ?)", now); err != nil {
			return fmt.Errorf("failed to record version 1: %w", err)
		}

		if err := SeedDefaultData(db); err != nil {
			return fmt.Errorf("failed to seed initial data: %w", err)
		}
		log.Println("[Migration] V1 migration and seed completed successfully.")
	}

	return nil
}
