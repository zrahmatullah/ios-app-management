package tests

import (
	"database/sql"
	"os"
	"path/filepath"
	"testing"
	"time"

	"lumina/core/domain"
	"lumina/core/migrations"
	"lumina/core/repository"
	"lumina/core/usecase"
	_ "modernc.org/sqlite"
)

func setupTestDB(t *testing.T) (*sql.DB, func()) {
	tmpDir, err := os.MkdirTemp("", "lumina_test_*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	dbPath := filepath.Join(tmpDir, "test_lumina.db")

	db, err := sql.Open("sqlite", dbPath+"?_pragma=busy_timeout(5000)&_pragma=journal_mode(WAL)&_pragma=foreign_keys(ON)")
	if err != nil {
		t.Fatalf("failed to open test sqlite: %v", err)
	}

	if err := migrations.RunMigrations(db); err != nil {
		t.Fatalf("failed to run migrations in test: %v", err)
	}

	cleanup := func() {
		_ = db.Close()
		_ = os.RemoveAll(tmpDir)
	}
	return db, cleanup
}

func TestAccountAndTransactionBalance(t *testing.T) {
	db, cleanup := setupTestDB(t)
	defer cleanup()

	repo := repository.NewFinanceRepository(db)

	// Verify default accounts seeded
	accounts, err := repo.ListAccounts()
	if err != nil {
		t.Fatalf("failed to list accounts: %v", err)
	}
	if len(accounts) == 0 {
		t.Fatal("expected default accounts to be seeded, got 0")
	}

	// 1. Create a dedicated test account
	acc := &domain.Account{
		Name:     "Test Wallet",
		Type:     domain.AccountTypeCash,
		Balance:  100000, // Rp 100.000
		Currency: "IDR",
		Color:    "#34C759",
		Icon:     "banknotes",
	}
	if err := repo.SaveAccount(acc); err != nil {
		t.Fatalf("failed to save account: %v", err)
	}

	// 2. Add Income of Rp 50.000
	txIncome := &domain.Transaction{
		AccountID:       acc.ID,
		Amount:          50000,
		Type:            domain.TxTypeIncome,
		Note:            "Bonus Test",
		TransactionDate: time.Now(),
	}
	if err := repo.CreateTransaction(txIncome); err != nil {
		t.Fatalf("failed to create income: %v", err)
	}

	accUpdated, err := repo.GetAccount(acc.ID)
	if err != nil {
		t.Fatalf("failed to fetch updated account: %v", err)
	}
	if accUpdated.Balance != 150000 {
		t.Errorf("expected balance 150000 after income, got %d", accUpdated.Balance)
	}

	// 3. Add Expense of Rp 30.000
	txExpense := &domain.Transaction{
		AccountID:       acc.ID,
		Amount:          30000,
		Type:            domain.TxTypeExpense,
		Note:            "Lunch Test",
		TransactionDate: time.Now(),
	}
	if err := repo.CreateTransaction(txExpense); err != nil {
		t.Fatalf("failed to create expense: %v", err)
	}

	accUpdated, err = repo.GetAccount(acc.ID)
	if err != nil {
		t.Fatalf("failed to fetch updated account: %v", err)
	}
	if accUpdated.Balance != 120000 {
		t.Errorf("expected balance 120000 after expense, got %d", accUpdated.Balance)
	}

	// 4. Delete Expense: balance should revert back to 150000
	if err := repo.DeleteTransaction(txExpense.ID); err != nil {
		t.Fatalf("failed to delete transaction: %v", err)
	}
	accUpdated, err = repo.GetAccount(acc.ID)
	if err != nil {
		t.Fatalf("failed to fetch updated account: %v", err)
	}
	if accUpdated.Balance != 150000 {
		t.Errorf("expected balance 150000 after deleting expense, got %d", accUpdated.Balance)
	}
}

func TestTransferBetweenAccounts(t *testing.T) {
	db, cleanup := setupTestDB(t)
	defer cleanup()

	repo := repository.NewFinanceRepository(db)
	u := usecase.NewFinanceUsecase(db)

	acc1 := &domain.Account{Name: "Account A", Type: domain.AccountTypeBank, Balance: 200000, Currency: "IDR"}
	acc2 := &domain.Account{Name: "Account B", Type: domain.AccountTypeCash, Balance: 50000, Currency: "IDR"}

	_ = repo.SaveAccount(acc1)
	_ = repo.SaveAccount(acc2)

	// Transfer 70.000 from acc1 to acc2
	err := u.Transfer(acc1.ID, acc2.ID, 70000, "Transfer Test", time.Now())
	if err != nil {
		t.Fatalf("transfer failed: %v", err)
	}

	a1, _ := repo.GetAccount(acc1.ID)
	a2, _ := repo.GetAccount(acc2.ID)

	if a1.Balance != 130000 {
		t.Errorf("acc1 expected 130000, got %d", a1.Balance)
	}
	if a2.Balance != 120000 {
		t.Errorf("acc2 expected 120000, got %d", a2.Balance)
	}
}

func TestSavingsProjectionAndDeposit(t *testing.T) {
	db, cleanup := setupTestDB(t)
	defer cleanup()

	sRepo := repository.NewSavingsRepository(db)
	fRepo := repository.NewFinanceRepository(db)
	sUsecase := usecase.NewSavingsUsecase(db)

	// Setup account with balance 1.000.000
	acc := &domain.Account{Name: "Bank Test", Type: domain.AccountTypeBank, Balance: 1000000, Currency: "IDR"}
	_ = fRepo.SaveAccount(acc)

	// Setup savings target 500.000 in 10 days
	deadline := time.Now().AddDate(0, 0, 10)
	sav := &domain.Savings{
		Name:         "Trip to Bali",
		TargetAmount: 500000,
		Deadline:     deadline,
	}
	if err := sRepo.SaveSavings(sav); err != nil {
		t.Fatalf("failed to create savings: %v", err)
	}

	// Deposit 200.000 linked to account
	err := sRepo.AddEntry(&domain.SavingsEntry{
		SavingsID: sav.ID,
		AccountID: &acc.ID,
		Amount:    200000,
		Type:      "DEPOSIT",
		Note:      "First deposit",
		EntryDate: time.Now(),
	})
	if err != nil {
		t.Fatalf("deposit failed: %v", err)
	}

	// Verify piggy bank balance
	savUpdated, _ := sRepo.GetSavings(sav.ID)
	if savUpdated.CurrentAmount != 200000 {
		t.Errorf("savings expected 200000, got %d", savUpdated.CurrentAmount)
	}

	// Verify linked account deducted
	accUpdated, _ := fRepo.GetAccount(acc.ID)
	if accUpdated.Balance != 800000 {
		t.Errorf("account expected 800000, got %d", accUpdated.Balance)
	}

	// Check projection
	proj, err := sUsecase.CalculateProjection(sav.ID)
	if err != nil {
		t.Fatalf("projection calculation failed: %v", err)
	}
	if proj.RemainingAmount != 300000 {
		t.Errorf("expected remaining 300000, got %d", proj.RemainingAmount)
	}
	if proj.ProgressPercentage < 0.39 || proj.ProgressPercentage > 0.41 {
		t.Errorf("expected progress ~40%%, got %f", proj.ProgressPercentage)
	}
}

func TestGoalsAndHabitStreaks(t *testing.T) {
	db, cleanup := setupTestDB(t)
	defer cleanup()

	gRepo := repository.NewGoalsRepository(db)

	// Test Goal Task progress
	goal := &domain.Goal{
		Title:    "Learn SwiftUI & Go",
		Category: "LEARNING",
		Deadline: time.Now().AddDate(0, 1, 0),
	}
	_ = gRepo.SaveGoal(goal)

	task1 := &domain.GoalTask{GoalID: goal.ID, Title: "Task 1", OrderIndex: 1}
	task2 := &domain.GoalTask{GoalID: goal.ID, Title: "Task 2", OrderIndex: 2}
	_ = gRepo.SaveGoalTask(task1)
	_ = gRepo.SaveGoalTask(task2)

	// Complete task 1
	_ = gRepo.ToggleGoalTask(task1.ID)

	goals, _ := gRepo.ListGoals()
	var foundGoal *domain.Goal
	for _, g := range goals {
		if g.ID == goal.ID {
			foundGoal = &g
			break
		}
	}
	if foundGoal == nil {
		t.Fatal("goal not found")
	}
	if foundGoal.Progress != 0.5 {
		t.Errorf("expected progress 0.5, got %f", foundGoal.Progress)
	}

	// Test Habit streak
	habit := &domain.Habit{
		Title: "Morning Run",
	}
	_ = gRepo.SaveHabit(habit)

	// Toggle today
	isDone, err := gRepo.ToggleHabitToday(habit.ID)
	if err != nil {
		t.Fatalf("habit toggle failed: %v", err)
	}
	if !isDone {
		t.Error("expected habit to be marked done")
	}

	habits, _ := gRepo.ListHabits()
	var foundHabit *domain.Habit
	for _, h := range habits {
		if h.ID == habit.ID {
			foundHabit = &h
			break
		}
	}
	if foundHabit == nil {
		t.Fatal("habit not found")
	}
	if foundHabit.StreakCurrent != 1 {
		t.Errorf("expected streak 1, got %d", foundHabit.StreakCurrent)
	}
}

func TestSafeToSpendAndRoundUp(t *testing.T) {
	db, cleanup := setupTestDB(t)
	defer cleanup()

	u := usecase.NewFinanceUsecase(db)

	// Safe to spend check
	safeInfo, err := u.CalculateSafeToSpend()
	if err != nil {
		t.Fatalf("failed to calculate safe to spend: %v", err)
	}
	if safeInfo.DailySafeAmount < 0 {
		t.Errorf("daily safe amount should be non-negative, got %d", safeInfo.DailySafeAmount)
	}

	// Round-up test: 32.500 rounded up to nearest 5.000 -> 35.000 (spare change: 2.500)
	roundRes := u.CalculateRoundUp(32500, 5000)
	if roundRes.RoundedAmount != 35000 {
		t.Errorf("expected rounded 35000, got %d", roundRes.RoundedAmount)
	}
	if roundRes.SpareChange != 2500 {
		t.Errorf("expected spare change 2500, got %d", roundRes.SpareChange)
	}

	// Round-up test: exactly 50.000 rounded to 5.000 -> 50.000 (spare change: 0)
	roundResExact := u.CalculateRoundUp(50000, 5000)
	if roundResExact.SpareChange != 0 {
		t.Errorf("expected spare change 0, got %d", roundResExact.SpareChange)
	}
}

