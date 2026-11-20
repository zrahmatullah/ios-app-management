package repository

import (
	"database/sql"
	"fmt"
	"time"

	"lumina/core/domain"
	"github.com/google/uuid"
)

type SavingsRepository struct {
	db *sql.DB
}

func NewSavingsRepository(db *sql.DB) *SavingsRepository {
	return &SavingsRepository{db: db}
}

func (r *SavingsRepository) ListSavings() ([]domain.Savings, error) {
	rows, err := r.db.Query(`
		SELECT id, name, target_amount, current_amount, deadline, icon, color, status, created_at, updated_at
		FROM savings
		ORDER BY status ASC, deadline ASC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.Savings
	for rows.Next() {
		var s domain.Savings
		var dLine, cAt, uAt string
		if err := rows.Scan(&s.ID, &s.Name, &s.TargetAmount, &s.CurrentAmount, &dLine, &s.Icon, &s.Color, &s.Status, &cAt, &uAt); err != nil {
			return nil, err
		}
		s.Deadline, _ = time.Parse(time.RFC3339, dLine)
		s.CreatedAt, _ = time.Parse(time.RFC3339, cAt)
		s.UpdatedAt, _ = time.Parse(time.RFC3339, uAt)
		list = append(list, s)
	}
	return list, nil
}

func (r *SavingsRepository) GetSavings(id string) (*domain.Savings, error) {
	var s domain.Savings
	var dLine, cAt, uAt string
	err := r.db.QueryRow(`
		SELECT id, name, target_amount, current_amount, deadline, icon, color, status, created_at, updated_at
		FROM savings
		WHERE id = ?
	`, id).Scan(&s.ID, &s.Name, &s.TargetAmount, &s.CurrentAmount, &dLine, &s.Icon, &s.Color, &s.Status, &cAt, &uAt)
	if err != nil {
		return nil, err
	}
	s.Deadline, _ = time.Parse(time.RFC3339, dLine)
	s.CreatedAt, _ = time.Parse(time.RFC3339, cAt)
	s.UpdatedAt, _ = time.Parse(time.RFC3339, uAt)
	return &s, nil
}

func (r *SavingsRepository) SaveSavings(s *domain.Savings) error {
	now := time.Now().UTC().Format(time.RFC3339)
	if s.Status == "" {
		s.Status = "ACTIVE"
	}
	if s.ID == "" {
		s.ID = uuid.New().String()
		_, err := r.db.Exec(`
			INSERT INTO savings (id, name, target_amount, current_amount, deadline, icon, color, status, created_at, updated_at)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, s.ID, s.Name, s.TargetAmount, s.CurrentAmount, s.Deadline.Format(time.RFC3339), s.Icon, s.Color, s.Status, now, now)
		return err
	}
	_, err := r.db.Exec(`
		UPDATE savings SET name = ?, target_amount = ?, deadline = ?, icon = ?, color = ?, status = ?, updated_at = ?
		WHERE id = ?
	`, s.Name, s.TargetAmount, s.Deadline.Format(time.RFC3339), s.Icon, s.Color, s.Status, now, s.ID)
	return err
}

func (r *SavingsRepository) DeleteSavings(id string) error {
	_, err := r.db.Exec(`DELETE FROM savings WHERE id = ?`, id)
	return err
}

// AddEntry adds a deposit or withdraw to savings, updating savings.current_amount and linked account atomically
func (r *SavingsRepository) AddEntry(entry *domain.SavingsEntry) error {
	dbtx, err := r.db.Begin()
	if err != nil {
		return err
	}
	defer dbtx.Rollback()

	if entry.ID == "" {
		entry.ID = uuid.New().String()
	}
	now := time.Now().UTC().Format(time.RFC3339)
	entryDate := entry.EntryDate.UTC().Format(time.RFC3339)

	_, err = dbtx.Exec(`
		INSERT INTO savings_entries (id, savings_id, account_id, amount, type, note, entry_date, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)
	`, entry.ID, entry.SavingsID, entry.AccountID, entry.Amount, entry.Type, entry.Note, entryDate, now)
	if err != nil {
		return fmt.Errorf("failed to insert savings entry: %w", err)
	}

	// Update savings current_amount
	var delta int64 = entry.Amount
	if entry.Type == "WITHDRAW" {
		delta = -entry.Amount
	}

	_, err = dbtx.Exec(`
		UPDATE savings
		SET current_amount = MAX(0, current_amount + ?),
		    status = CASE WHEN (current_amount + ?) >= target_amount THEN 'COMPLETED' ELSE 'ACTIVE' END,
		    updated_at = ?
		WHERE id = ?
	`, delta, delta, now, entry.SavingsID)
	if err != nil {
		return fmt.Errorf("failed to update savings balance: %w", err)
	}

	// If account linked, adjust account balance too
	if entry.AccountID != nil && *entry.AccountID != "" {
		if entry.Type == "DEPOSIT" {
			// money moves from account into savings piggy bank
			_, err = dbtx.Exec(`UPDATE accounts SET balance = balance - ?, updated_at = ? WHERE id = ?`, entry.Amount, now, *entry.AccountID)
		} else if entry.Type == "WITHDRAW" {
			// money moves back from savings into account
			_, err = dbtx.Exec(`UPDATE accounts SET balance = balance + ?, updated_at = ? WHERE id = ?`, entry.Amount, now, *entry.AccountID)
		}
		if err != nil {
			return fmt.Errorf("failed to update linked account balance: %w", err)
		}
	}

	return dbtx.Commit()
}

func (r *SavingsRepository) ListEntries(savingsID string) ([]domain.SavingsEntry, error) {
	rows, err := r.db.Query(`
		SELECT id, savings_id, account_id, amount, type, note, entry_date, created_at
		FROM savings_entries
		WHERE savings_id = ?
		ORDER BY entry_date DESC
	`, savingsID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.SavingsEntry
	for rows.Next() {
		var e domain.SavingsEntry
		var accID sql.NullString
		var eDate, cAt string
		if err := rows.Scan(&e.ID, &e.SavingsID, &accID, &e.Amount, &e.Type, &e.Note, &eDate, &cAt); err != nil {
			return nil, err
		}
		if accID.Valid {
			e.AccountID = &accID.String
		}
		e.EntryDate, _ = time.Parse(time.RFC3339, eDate)
		e.CreatedAt, _ = time.Parse(time.RFC3339, cAt)
		list = append(list, e)
	}
	return list, nil
}
