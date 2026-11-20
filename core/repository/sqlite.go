package repository

import (
	"database/sql"
	"fmt"
	"sync"

	"lumina/core/migrations"
	_ "modernc.org/sqlite"
)

// Database wraps the sql.DB instance and provides concurrency safety
type Database struct {
	db   *sql.DB
	path string
	mu   sync.RWMutex
}

var (
	instance *Database
	once     sync.Once
)

// InitDB initializes SQLite connection with WAL mode and runs migrations
func InitDB(dbPath string) (*Database, error) {
	var initErr error
	once.Do(func() {
		dsn := fmt.Sprintf("%s?_pragma=busy_timeout(5000)&_pragma=journal_mode(WAL)&_pragma=foreign_keys(ON)", dbPath)
		db, err := sql.Open("sqlite", dsn)
		if err != nil {
			initErr = fmt.Errorf("failed to open sqlite database at %s: %w", dbPath, err)
			return
		}

		// Ensure single writer / multi-reader safety in mobile environment
		db.SetMaxOpenConns(1)
		db.SetMaxIdleConns(1)

		if err := db.Ping(); err != nil {
			initErr = fmt.Errorf("failed to ping database: %w", err)
			return
		}

		if err := migrations.RunMigrations(db); err != nil {
			initErr = fmt.Errorf("failed to run migrations: %w", err)
			return
		}

		instance = &Database{
			db:   db,
			path: dbPath,
		}
	})

	if initErr != nil {
		return nil, initErr
	}
	return instance, nil
}

// GetDB returns active Database instance
func GetDB() *Database {
	return instance
}

// DB returns the underlying sql.DB
func (d *Database) DB() *sql.DB {
	return d.db
}

// Close gracefully closes the SQLite database
func (d *Database) Close() error {
	d.mu.Lock()
	defer d.mu.Unlock()
	if d.db != nil {
		return d.db.Close()
	}
	return nil
}
