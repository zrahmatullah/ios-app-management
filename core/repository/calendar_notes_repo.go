package repository

import (
	"database/sql"
	"encoding/csv"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"lumina/core/domain"
	"github.com/google/uuid"
)

type CalendarNotesRepository struct {
	db *sql.DB
}

func NewCalendarNotesRepository(db *sql.DB) *CalendarNotesRepository {
	return &CalendarNotesRepository{db: db}
}

// ================= EVENTS =================

func (r *CalendarNotesRepository) ListEvents(start, end *time.Time) ([]domain.Event, error) {
	sqlQuery := `
		SELECT id, title, start_time, end_time, location, color, recurrence, reminder_minutes, is_completed, created_at, updated_at
		FROM events
		WHERE 1=1
	`
	var args []interface{}
	if start != nil {
		sqlQuery += ` AND end_time >= ?`
		args = append(args, start.UTC().Format(time.RFC3339))
	}
	if end != nil {
		sqlQuery += ` AND start_time <= ?`
		args = append(args, end.UTC().Format(time.RFC3339))
	}
	sqlQuery += ` ORDER BY start_time ASC`

	rows, err := r.db.Query(sqlQuery, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.Event
	for rows.Next() {
		var e domain.Event
		var sTime, eTime, cAt, uAt string
		var isComp int
		if err := rows.Scan(&e.ID, &e.Title, &sTime, &eTime, &e.Location, &e.Color, &e.Recurrence, &e.ReminderMinutes, &isComp, &cAt, &uAt); err != nil {
			return nil, err
		}
		e.StartTime, _ = time.Parse(time.RFC3339, sTime)
		e.EndTime, _ = time.Parse(time.RFC3339, eTime)
		e.IsCompleted = isComp == 1
		e.CreatedAt, _ = time.Parse(time.RFC3339, cAt)
		e.UpdatedAt, _ = time.Parse(time.RFC3339, uAt)
		list = append(list, e)
	}
	return list, nil
}

func (r *CalendarNotesRepository) SaveEvent(e *domain.Event) error {
	now := time.Now().UTC().Format(time.RFC3339)
	isComp := 0
	if e.IsCompleted {
		isComp = 1
	}
	if e.ID == "" {
		e.ID = uuid.New().String()
		_, err := r.db.Exec(`
			INSERT INTO events (id, title, start_time, end_time, location, color, recurrence, reminder_minutes, is_completed, created_at, updated_at)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, e.ID, e.Title, e.StartTime.Format(time.RFC3339), e.EndTime.Format(time.RFC3339), e.Location, e.Color, e.Recurrence, e.ReminderMinutes, isComp, now, now)
		return err
	}
	_, err := r.db.Exec(`
		UPDATE events SET title = ?, start_time = ?, end_time = ?, location = ?, color = ?, recurrence = ?, reminder_minutes = ?, is_completed = ?, updated_at = ?
		WHERE id = ?
	`, e.Title, e.StartTime.Format(time.RFC3339), e.EndTime.Format(time.RFC3339), e.Location, e.Color, e.Recurrence, e.ReminderMinutes, isComp, now, e.ID)
	return err
}

func (r *CalendarNotesRepository) DeleteEvent(id string) error {
	_, err := r.db.Exec(`DELETE FROM events WHERE id = ?`, id)
	return err
}

// ================= NOTES & FTS5 =================

func (r *CalendarNotesRepository) ListNotes(searchQuery *string, tag *string, pinnedOnly bool, archivedOnly bool) ([]domain.Note, error) {
	var sqlQuery string
	var args []interface{}

	if searchQuery != nil && strings.TrimSpace(*searchQuery) != "" {
		// Use SQLite FTS5 search
		ftsTerm := strings.TrimSpace(*searchQuery) + "*"
		sqlQuery = `
			SELECT n.id, n.title, n.content, n.mood, n.is_pinned, n.is_archived, n.note_date, n.created_at, n.updated_at
			FROM notes_fts fts
			JOIN notes n ON fts.note_id = n.id
			WHERE notes_fts MATCH ? AND n.deleted_at IS NULL
		`
		args = append(args, ftsTerm)
	} else {
		sqlQuery = `
			SELECT n.id, n.title, n.content, n.mood, n.is_pinned, n.is_archived, n.note_date, n.created_at, n.updated_at
			FROM notes n
			WHERE n.deleted_at IS NULL
		`
	}

	if pinnedOnly {
		sqlQuery += ` AND n.is_pinned = 1`
	}
	if archivedOnly {
		sqlQuery += ` AND n.is_archived = 1`
	} else {
		sqlQuery += ` AND n.is_archived = 0`
	}

	sqlQuery += ` ORDER BY n.is_pinned DESC, n.note_date DESC, n.created_at DESC`

	rows, err := r.db.Query(sqlQuery, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.Note
	for rows.Next() {
		var n domain.Note
		var isPin, isArch int
		var nDate, cAt, uAt string
		if err := rows.Scan(&n.ID, &n.Title, &n.Content, &n.Mood, &isPin, &isArch, &nDate, &cAt, &uAt); err != nil {
			return nil, err
		}
		n.IsPinned = isPin == 1
		n.IsArchived = isArch == 1
		n.NoteDate, _ = time.Parse(time.RFC3339, nDate)
		n.CreatedAt, _ = time.Parse(time.RFC3339, cAt)
		n.UpdatedAt, _ = time.Parse(time.RFC3339, uAt)

		// Fetch tags
		tags, _ := r.getTagsForNote(n.ID)
		n.Tags = tags

		list = append(list, n)
	}
	return list, nil
}

func (r *CalendarNotesRepository) SaveNote(n *domain.Note) error {
	dbtx, err := r.db.Begin()
	if err != nil {
		return err
	}
	defer dbtx.Rollback()

	now := time.Now().UTC().Format(time.RFC3339)
	isPin := 0
	if n.IsPinned {
		isPin = 1
	}
	isArch := 0
	if n.IsArchived {
		isArch = 1
	}
	nDate := n.NoteDate.UTC().Format(time.RFC3339)
	if n.NoteDate.IsZero() {
		nDate = now
	}

	if n.ID == "" {
		n.ID = uuid.New().String()
		_, err := dbtx.Exec(`
			INSERT INTO notes (id, title, content, mood, is_pinned, is_archived, note_date, created_at, updated_at)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, n.ID, n.Title, n.Content, n.Mood, isPin, isArch, nDate, now, now)
		if err != nil {
			return err
		}
	} else {
		_, err := dbtx.Exec(`
			UPDATE notes SET title = ?, content = ?, mood = ?, is_pinned = ?, is_archived = ?, note_date = ?, updated_at = ?
			WHERE id = ?
		`, n.Title, n.Content, n.Mood, isPin, isArch, nDate, now, n.ID)
		if err != nil {
			return err
		}
	}

	// Update tags
	_, _ = dbtx.Exec(`DELETE FROM note_tags WHERE note_id = ?`, n.ID)
	for _, tag := range n.Tags {
		tag = strings.TrimSpace(tag)
		if tag == "" {
			continue
		}
		var tagID string
		err := dbtx.QueryRow(`SELECT id FROM tags WHERE name = ?`, tag).Scan(&tagID)
		if err != nil {
			tagID = uuid.New().String()
			_, _ = dbtx.Exec(`INSERT INTO tags (id, name, color) VALUES (?, ?, '#007AFF')`, tagID, tag)
		}
		_, _ = dbtx.Exec(`INSERT OR IGNORE INTO note_tags (note_id, tag_id) VALUES (?, ?)`, n.ID, tagID)
	}

	return dbtx.Commit()
}

func (r *CalendarNotesRepository) DeleteNote(id string) error {
	now := time.Now().UTC().Format(time.RFC3339)
	_, err := r.db.Exec(`UPDATE notes SET deleted_at = ? WHERE id = ?`, now, id)
	return err
}

func (r *CalendarNotesRepository) getTagsForNote(noteID string) ([]string, error) {
	rows, err := r.db.Query(`
		SELECT t.name FROM tags t
		JOIN note_tags nt ON t.id = nt.tag_id
		WHERE nt.note_id = ?
		ORDER BY t.name ASC
	`, noteID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tags []string
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err == nil {
			tags = append(tags, name)
		}
	}
	return tags, nil
}

// ================= SETTINGS =================

func (r *CalendarNotesRepository) GetSetting(key string) string {
	var val string
	_ = r.db.QueryRow(`SELECT value FROM settings WHERE key = ?`, key).Scan(&val)
	return val
}

func (r *CalendarNotesRepository) SetSetting(key, val string) error {
	now := time.Now().UTC().Format(time.RFC3339)
	_, err := r.db.Exec(`
		INSERT INTO settings (key, value, updated_at) VALUES (?, ?, ?)
		ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at
	`, key, val, now)
	return err
}

func (r *CalendarNotesRepository) GetAllSettings() (map[string]string, error) {
	rows, err := r.db.Query(`SELECT key, value FROM settings`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	res := make(map[string]string)
	for rows.Next() {
		var k, v string
		if err := rows.Scan(&k, &v); err == nil {
			res[k] = v
		}
	}
	return res, nil
}

// ================= BACKUP & EXPORT =================

type FullBackupData struct {
	Version      int                  `json:"version"`
	ExportedAt   string               `json:"exported_at"`
	Accounts     []domain.Account     `json:"accounts"`
	Categories   []domain.Category    `json:"categories"`
	Transactions []domain.Transaction `json:"transactions"`
	Savings      []domain.Savings     `json:"savings"`
	Goals        []domain.Goal        `json:"goals"`
	Habits       []domain.Habit       `json:"habits"`
	Events       []domain.Event       `json:"events"`
	Notes        []domain.Note        `json:"notes"`
	Settings     map[string]string    `json:"settings"`
}

func (r *CalendarNotesRepository) ExportFullBackup() (string, error) {
	backup := FullBackupData{
		Version:    1,
		ExportedAt: time.Now().UTC().Format(time.RFC3339),
	}

	var err error
	settings, _ := r.GetAllSettings()
	backup.Settings = settings

	// Accounts
	aRepo := NewFinanceRepository(r.db)
	backup.Accounts, err = aRepo.ListAccounts()
	if err != nil {
		return "", err
	}

	// Categories
	backup.Categories, err = aRepo.ListCategories(nil)
	if err != nil {
		return "", err
	}

	// Transactions
	backup.Transactions, err = aRepo.FilterTransactions(nil, nil, nil, nil, nil, 0, 0)
	if err != nil {
		return "", err
	}

	// Savings
	sRepo := NewSavingsRepository(r.db)
	backup.Savings, err = sRepo.ListSavings()
	if err != nil {
		return "", err
	}

	// Goals & Habits
	gRepo := NewGoalsRepository(r.db)
	backup.Goals, err = gRepo.ListGoals()
	if err != nil {
		return "", err
	}
	backup.Habits, err = gRepo.ListHabits()
	if err != nil {
		return "", err
	}

	// Events & Notes
	backup.Events, err = r.ListEvents(nil, nil)
	if err != nil {
		return "", err
	}
	backup.Notes, err = r.ListNotes(nil, nil, false, false)
	if err != nil {
		return "", err
	}

	bytes, err := json.MarshalIndent(backup, "", "  ")
	if err != nil {
		return "", err
	}
	return string(bytes), nil
}

func (r *CalendarNotesRepository) ExportTransactionsCSV() (string, error) {
	aRepo := NewFinanceRepository(r.db)
	txs, err := aRepo.FilterTransactions(nil, nil, nil, nil, nil, 0, 0)
	if err != nil {
		return "", err
	}

	var sb strings.Builder
	writer := csv.NewWriter(&sb)
	_ = writer.Write([]string{"Date", "Type", "Amount", "Account", "To Account", "Category", "Note"})

	for _, tx := range txs {
		toAcc := ""
		if tx.ToAccountName != nil {
			toAcc = *tx.ToAccountName
		}
		cat := ""
		if tx.CategoryName != nil {
			cat = *tx.CategoryName
		}
		_ = writer.Write([]string{
			tx.TransactionDate.Format("2006-01-02 15:04"),
			string(tx.Type),
			fmt.Sprintf("%d", tx.Amount),
			tx.AccountName,
			toAcc,
			cat,
			tx.Note,
		})
	}
	writer.Flush()
	return sb.String(), nil
}
