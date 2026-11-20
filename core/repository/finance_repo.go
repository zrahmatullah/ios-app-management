package repository

import (
	"database/sql"
	"fmt"
	"time"

	"lumina/core/domain"
	"github.com/google/uuid"
)

type FinanceRepository struct {
	db *sql.DB
}

func NewFinanceRepository(db *sql.DB) *FinanceRepository {
	return &FinanceRepository{db: db}
}

// ================= ACCOUNTS =================

func (r *FinanceRepository) ListAccounts() ([]domain.Account, error) {
	rows, err := r.db.Query(`
		SELECT id, name, type, balance, currency, color, icon, is_archived, created_at, updated_at
		FROM accounts
		WHERE deleted_at IS NULL
		ORDER BY created_at ASC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.Account
	for rows.Next() {
		var a domain.Account
		var isArchived int
		var cAt, uAt string
		if err := rows.Scan(&a.ID, &a.Name, &a.Type, &a.Balance, &a.Currency, &a.Color, &a.Icon, &isArchived, &cAt, &uAt); err != nil {
			return nil, err
		}
		a.IsArchived = isArchived == 1
		a.CreatedAt, _ = time.Parse(time.RFC3339, cAt)
		a.UpdatedAt, _ = time.Parse(time.RFC3339, uAt)
		list = append(list, a)
	}
	return list, nil
}

func (r *FinanceRepository) GetAccount(id string) (*domain.Account, error) {
	var a domain.Account
	var isArchived int
	var cAt, uAt string
	err := r.db.QueryRow(`
		SELECT id, name, type, balance, currency, color, icon, is_archived, created_at, updated_at
		FROM accounts
		WHERE id = ? AND deleted_at IS NULL
	`, id).Scan(&a.ID, &a.Name, &a.Type, &a.Balance, &a.Currency, &a.Color, &a.Icon, &isArchived, &cAt, &uAt)
	if err != nil {
		return nil, err
	}
	a.IsArchived = isArchived == 1
	a.CreatedAt, _ = time.Parse(time.RFC3339, cAt)
	a.UpdatedAt, _ = time.Parse(time.RFC3339, uAt)
	return &a, nil
}

func (r *FinanceRepository) SaveAccount(acc *domain.Account) error {
	now := time.Now().UTC().Format(time.RFC3339)
	if acc.ID == "" {
		acc.ID = uuid.New().String()
		_, err := r.db.Exec(`
			INSERT INTO accounts (id, name, type, balance, currency, color, icon, is_archived, created_at, updated_at)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, acc.ID, acc.Name, acc.Type, acc.Balance, acc.Currency, acc.Color, acc.Icon, 0, now, now)
		return err
	}
	_, err := r.db.Exec(`
		UPDATE accounts SET name = ?, type = ?, color = ?, icon = ?, updated_at = ?
		WHERE id = ?
	`, acc.Name, acc.Type, acc.Color, acc.Icon, now, acc.ID)
	return err
}

func (r *FinanceRepository) DeleteAccount(id string) error {
	now := time.Now().UTC().Format(time.RFC3339)
	_, err := r.db.Exec(`UPDATE accounts SET deleted_at = ? WHERE id = ?`, now, id)
	return err
}

// ================= CATEGORIES =================

func (r *FinanceRepository) ListCategories(catType *domain.TransactionType) ([]domain.Category, error) {
	query := `SELECT id, name, type, icon, color, is_default, created_at, updated_at FROM categories`
	var args []interface{}
	if catType != nil {
		query += ` WHERE type = ?`
		args = append(args, *catType)
	}
	query += ` ORDER BY name ASC`

	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.Category
	for rows.Next() {
		var c domain.Category
		var isDef int
		var cAt, uAt string
		if err := rows.Scan(&c.ID, &c.Name, &c.Type, &c.Icon, &c.Color, &isDef, &cAt, &uAt); err != nil {
			return nil, err
		}
		c.IsDefault = isDef == 1
		c.CreatedAt, _ = time.Parse(time.RFC3339, cAt)
		c.UpdatedAt, _ = time.Parse(time.RFC3339, uAt)
		list = append(list, c)
	}
	return list, nil
}

func (r *FinanceRepository) SaveCategory(cat *domain.Category) error {
	now := time.Now().UTC().Format(time.RFC3339)
	if cat.ID == "" {
		cat.ID = uuid.New().String()
		_, err := r.db.Exec(`
			INSERT INTO categories (id, name, type, icon, color, is_default, created_at, updated_at)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?)
		`, cat.ID, cat.Name, cat.Type, cat.Icon, cat.Color, 0, now, now)
		return err
	}
	_, err := r.db.Exec(`
		UPDATE categories SET name = ?, icon = ?, color = ?, updated_at = ?
		WHERE id = ?
	`, cat.Name, cat.Icon, cat.Color, now, cat.ID)
	return err
}

// ================= TRANSACTIONS =================

// CreateTransaction executes an atomic transaction insertion and balance adjustments
func (r *FinanceRepository) CreateTransaction(tx *domain.Transaction) error {
	dbtx, err := r.db.Begin()
	if err != nil {
		return err
	}
	defer dbtx.Rollback()

	if tx.ID == "" {
		tx.ID = uuid.New().String()
	}
	now := time.Now().UTC().Format(time.RFC3339)
	txDate := tx.TransactionDate.UTC().Format(time.RFC3339)

	_, err = dbtx.Exec(`
		INSERT INTO transactions (id, account_id, to_account_id, category_id, amount, type, note, transaction_date, receipt_path, recurring_rule_id, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	`, tx.ID, tx.AccountID, tx.ToAccountID, tx.CategoryID, tx.Amount, tx.Type, tx.Note, txDate, tx.ReceiptPath, tx.RecurringRuleID, now, now)
	if err != nil {
		return fmt.Errorf("failed to insert transaction: %w", err)
	}

	// Update account balances
	switch tx.Type {
	case domain.TxTypeIncome:
		_, err = dbtx.Exec(`UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?`, tx.Amount, now, tx.AccountID)
	case domain.TxTypeExpense:
		_, err = dbtx.Exec(`UPDATE accounts SET balance = balance - ?, updated_at = ? WHERE id = ?`, tx.Amount, now, tx.AccountID)
	case domain.TxTypeTransfer:
		if tx.ToAccountID == nil {
			return fmt.Errorf("transfer requires to_account_id")
		}
		_, err = dbtx.Exec(`UPDATE accounts SET balance = balance - ?, updated_at = ? WHERE id = ?`, tx.Amount, now, tx.AccountID)
		if err == nil {
			_, err = dbtx.Exec(`UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?`, tx.Amount, now, *tx.ToAccountID)
		}
	}
	if err != nil {
		return fmt.Errorf("failed to update balances: %w", err)
	}

	return dbtx.Commit()
}

// DeleteTransaction atomically reverts balance change and marks transaction deleted
func (r *FinanceRepository) DeleteTransaction(id string) error {
	dbtx, err := r.db.Begin()
	if err != nil {
		return err
	}
	defer dbtx.Rollback()

	var tx domain.Transaction
	var txType string
	var toAccID sql.NullString
	err = dbtx.QueryRow(`
		SELECT account_id, to_account_id, amount, type
		FROM transactions
		WHERE id = ? AND deleted_at IS NULL
	`, id).Scan(&tx.AccountID, &toAccID, &tx.Amount, &txType)
	if err != nil {
		return err
	}
	tx.Type = domain.TransactionType(txType)
	if toAccID.Valid {
		val := toAccID.String
		tx.ToAccountID = &val
	}

	now := time.Now().UTC().Format(time.RFC3339)

	// Revert balance
	switch tx.Type {
	case domain.TxTypeIncome:
		_, err = dbtx.Exec(`UPDATE accounts SET balance = balance - ?, updated_at = ? WHERE id = ?`, tx.Amount, now, tx.AccountID)
	case domain.TxTypeExpense:
		_, err = dbtx.Exec(`UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?`, tx.Amount, now, tx.AccountID)
	case domain.TxTypeTransfer:
		if tx.ToAccountID != nil {
			_, err = dbtx.Exec(`UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?`, tx.Amount, now, tx.AccountID)
			if err == nil {
				_, err = dbtx.Exec(`UPDATE accounts SET balance = balance - ?, updated_at = ? WHERE id = ?`, tx.Amount, now, *tx.ToAccountID)
			}
		}
	}
	if err != nil {
		return fmt.Errorf("failed to revert balance: %w", err)
	}

	_, err = dbtx.Exec(`UPDATE transactions SET deleted_at = ?, updated_at = ? WHERE id = ?`, now, now, id)
	if err != nil {
		return err
	}

	return dbtx.Commit()
}

// FilterTransactions retrieves transactions with flexible filters
func (r *FinanceRepository) FilterTransactions(startDate, endDate *time.Time, categoryID, accountID *string, query *string, limit, offset int) ([]domain.Transaction, error) {
	sqlQuery := `
		SELECT t.id, t.account_id, a.name, t.to_account_id, a2.name, t.category_id, c.name, c.icon, c.color,
		       t.amount, t.type, t.note, t.transaction_date, t.receipt_path, t.recurring_rule_id, t.created_at, t.updated_at
		FROM transactions t
		JOIN accounts a ON t.account_id = a.id
		LEFT JOIN accounts a2 ON t.to_account_id = a2.id
		LEFT JOIN categories c ON t.category_id = c.id
		WHERE t.deleted_at IS NULL
	`
	var args []interface{}

	if startDate != nil {
		sqlQuery += ` AND t.transaction_date >= ?`
		args = append(args, startDate.UTC().Format(time.RFC3339))
	}
	if endDate != nil {
		sqlQuery += ` AND t.transaction_date <= ?`
		args = append(args, endDate.UTC().Format(time.RFC3339))
	}
	if categoryID != nil && *categoryID != "" {
		sqlQuery += ` AND t.category_id = ?`
		args = append(args, *categoryID)
	}
	if accountID != nil && *accountID != "" {
		sqlQuery += ` AND (t.account_id = ? OR t.to_account_id = ?)`
		args = append(args, *accountID, *accountID)
	}
	if query != nil && *query != "" {
		sqlQuery += ` AND (t.note LIKE ? OR c.name LIKE ?)`
		likeQuery := "%" + *query + "%"
		args = append(args, likeQuery, likeQuery)
	}

	sqlQuery += ` ORDER BY t.transaction_date DESC, t.created_at DESC`
	if limit > 0 {
		sqlQuery += ` LIMIT ? OFFSET ?`
		args = append(args, limit, offset)
	}

	rows, err := r.db.Query(sqlQuery, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.Transaction
	for rows.Next() {
		var tx domain.Transaction
		var toAccID, toAccName, catID, catName, catIcon, catColor, recurID sql.NullString
		var txDate, cAt, uAt string

		err := rows.Scan(
			&tx.ID, &tx.AccountID, &tx.AccountName, &toAccID, &toAccName,
			&catID, &catName, &catIcon, &catColor,
			&tx.Amount, &tx.Type, &tx.Note, &txDate, &tx.ReceiptPath, &recurID, &cAt, &uAt,
		)
		if err != nil {
			return nil, err
		}

		if toAccID.Valid {
			tx.ToAccountID = &toAccID.String
			tx.ToAccountName = &toAccName.String
		}
		if catID.Valid {
			tx.CategoryID = &catID.String
			tx.CategoryName = &catName.String
			tx.CategoryIcon = &catIcon.String
			tx.CategoryColor = &catColor.String
		}
		if recurID.Valid {
			tx.RecurringRuleID = &recurID.String
		}

		tx.TransactionDate, _ = time.Parse(time.RFC3339, txDate)
		tx.CreatedAt, _ = time.Parse(time.RFC3339, cAt)
		tx.UpdatedAt, _ = time.Parse(time.RFC3339, uAt)

		list = append(list, tx)
	}
	return list, nil
}

// GetMonthSummary returns income and expense totals for given month (1..12) and year
func (r *FinanceRepository) GetMonthSummary(year int, month int) (income int64, expense int64, err error) {
	start := time.Date(year, time.Month(month), 1, 0, 0, 0, 0, time.UTC).Format(time.RFC3339)
	end := time.Date(year, time.Month(month)+1, 1, 0, 0, 0, 0, time.UTC).Format(time.RFC3339)

	row := r.db.QueryRow(`
		SELECT
			COALESCE(SUM(CASE WHEN type = 'INCOME' THEN amount ELSE 0 END), 0),
			COALESCE(SUM(CASE WHEN type = 'EXPENSE' THEN amount ELSE 0 END), 0)
		FROM transactions
		WHERE deleted_at IS NULL AND transaction_date >= ? AND transaction_date < ?
	`, start, end)

	err = row.Scan(&income, &expense)
	return
}

// ================= BUDGETS =================

func (r *FinanceRepository) ListBudgets(year int, month int) ([]domain.Budget, error) {
	start := time.Date(year, time.Month(month), 1, 0, 0, 0, 0, time.UTC).Format(time.RFC3339)
	end := time.Date(year, time.Month(month)+1, 1, 0, 0, 0, 0, time.UTC).Format(time.RFC3339)

	rows, err := r.db.Query(`
		SELECT b.id, b.category_id, c.name, c.icon, c.color, b.amount, b.period, b.start_date, b.alert_threshold,
		       COALESCE((
		           SELECT SUM(t.amount)
		           FROM transactions t
		           WHERE t.category_id = b.category_id
		             AND t.type = 'EXPENSE'
		             AND t.deleted_at IS NULL
		             AND t.transaction_date >= ? AND t.transaction_date < ?
		       ), 0) AS spent,
		       b.created_at, b.updated_at
		FROM budgets b
		JOIN categories c ON b.category_id = c.id
		ORDER BY b.amount DESC
	`, start, end)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.Budget
	for rows.Next() {
		var b domain.Budget
		var sDate, cAt, uAt string
		err := rows.Scan(
			&b.ID, &b.CategoryID, &b.CategoryName, &b.CategoryIcon, &b.CategoryColor,
			&b.Amount, &b.Period, &sDate, &b.AlertThreshold, &b.Spent, &cAt, &uAt,
		)
		if err != nil {
			return nil, err
		}
		b.StartDate, _ = time.Parse(time.RFC3339, sDate)
		b.CreatedAt, _ = time.Parse(time.RFC3339, cAt)
		b.UpdatedAt, _ = time.Parse(time.RFC3339, uAt)
		list = append(list, b)
	}
	return list, nil
}

func (r *FinanceRepository) SaveBudget(b *domain.Budget) error {
	now := time.Now().UTC().Format(time.RFC3339)
	if b.ID == "" {
		b.ID = uuid.New().String()
		_, err := r.db.Exec(`
			INSERT INTO budgets (id, category_id, amount, period, start_date, alert_threshold, created_at, updated_at)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?)
			ON CONFLICT(category_id, period) DO UPDATE SET amount = excluded.amount, alert_threshold = excluded.alert_threshold, updated_at = excluded.updated_at
		`, b.ID, b.CategoryID, b.Amount, b.Period, b.StartDate.Format(time.RFC3339), b.AlertThreshold, now, now)
		return err
	}
	_, err := r.db.Exec(`
		UPDATE budgets SET amount = ?, alert_threshold = ?, updated_at = ? WHERE id = ?
	`, b.Amount, b.AlertThreshold, now, b.ID)
	return err
}

func (r *FinanceRepository) DeleteBudget(id string) error {
	_, err := r.db.Exec(`DELETE FROM budgets WHERE id = ?`, id)
	return err
}
