package usecase

import (
	"database/sql"
	"fmt"
	"time"

	"lumina/core/domain"
	"lumina/core/repository"
)

type FinanceUsecase struct {
	financeRepo       *repository.FinanceRepository
	savingsRepo       *repository.SavingsRepository
	goalsRepo         *repository.GoalsRepository
	calendarNotesRepo *repository.CalendarNotesRepository
}

func NewFinanceUsecase(db *sql.DB) *FinanceUsecase {
	return &FinanceUsecase{
		financeRepo:       repository.NewFinanceRepository(db),
		savingsRepo:       repository.NewSavingsRepository(db),
		goalsRepo:         repository.NewGoalsRepository(db),
		calendarNotesRepo: repository.NewCalendarNotesRepository(db),
	}
}

// GetDashboardSummary aggregates all high-level cards for the Home screen
func (u *FinanceUsecase) GetDashboardSummary() (*domain.DashboardSummary, error) {
	summary := &domain.DashboardSummary{}

	// 1. Total Balance across all unarchived accounts
	accounts, err := u.financeRepo.ListAccounts()
	if err == nil {
		for _, acc := range accounts {
			if !acc.IsArchived {
				summary.TotalBalance += acc.Balance
			}
		}
	}

	// 2. Month Income and Expense
	now := time.Now()
	inc, exp, err := u.financeRepo.GetMonthSummary(now.Year(), int(now.Month()))
	if err == nil {
		summary.MonthIncome = inc
		summary.MonthExpense = exp
	}

	// 3. Top Savings (up to 3)
	savings, err := u.savingsRepo.ListSavings()
	if err == nil {
		if len(savings) > 3 {
			summary.TopSavings = savings[:3]
		} else {
			summary.TopSavings = savings
		}
	}

	// 4. Top Goals (up to 3 active goals)
	goals, err := u.goalsRepo.ListGoals()
	if err == nil {
		var activeGoals []domain.Goal
		for _, g := range goals {
			if g.Status == domain.GoalStatusActive {
				activeGoals = append(activeGoals, g)
				if len(activeGoals) == 3 {
					break
				}
			}
		}
		summary.TopGoals = activeGoals
	}

	// 5. Today's Events
	todayStart := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.Local)
	todayEnd := todayStart.Add(24 * time.Hour)
	events, err := u.calendarNotesRepo.ListEvents(&todayStart, &todayEnd)
	if err == nil {
		summary.TodayEvents = events
	}

	// 6. Recent Notes (up to 3)
	notes, err := u.calendarNotesRepo.ListNotes(nil, nil, false, false)
	if err == nil {
		if len(notes) > 3 {
			summary.RecentNotes = notes[:3]
		} else {
			summary.RecentNotes = notes
		}
	}

	// 7. Recent Transactions (up to 5)
	txs, err := u.financeRepo.FilterTransactions(nil, nil, nil, nil, nil, 5, 0)
	if err == nil {
		summary.RecentTransactions = txs
	}

	// 8. Habits Today
	habits, err := u.goalsRepo.ListHabits()
	if err == nil {
		summary.HabitsToday = habits
	}

	return summary, nil
}

// GetFinanceReport compiles analytics for daily, weekly, monthly, or yearly periods
func (u *FinanceUsecase) GetFinanceReport(startDate, endDate time.Time) (*domain.FinanceReport, error) {
	txs, err := u.financeRepo.FilterTransactions(&startDate, &endDate, nil, nil, nil, 0, 0)
	if err != nil {
		return nil, err
	}

	report := &domain.FinanceReport{
		CategoryExpense: make(map[string]int64),
	}

	dailyMap := make(map[string]*domain.DailyTrendPoint)

	for _, tx := range txs {
		dateKey := tx.TransactionDate.Format("2006-01-02")
		point, exists := dailyMap[dateKey]
		if !exists {
			point = &domain.DailyTrendPoint{Date: dateKey}
			dailyMap[dateKey] = point
		}

		if tx.Type == domain.TxTypeIncome {
			report.TotalIncome += tx.Amount
			point.Income += tx.Amount
		} else if tx.Type == domain.TxTypeExpense {
			report.TotalExpense += tx.Amount
			point.Expense += tx.Amount

			catName := "Lainnya"
			if tx.CategoryName != nil && *tx.CategoryName != "" {
				catName = *tx.CategoryName
			}
			report.CategoryExpense[catName] += tx.Amount
		}
	}

	report.NetSavings = report.TotalIncome - report.TotalExpense

	// Flatten daily trend
	for _, p := range dailyMap {
		report.DailyTrend = append(report.DailyTrend, *p)
	}

	return report, nil
}

// Transfer creates a transfer transaction between two accounts
func (u *FinanceUsecase) Transfer(fromAccID, toAccID string, amount int64, note string, date time.Time) error {
	if fromAccID == toAccID {
		return fmt.Errorf("source and destination account cannot be identical")
	}
	if amount <= 0 {
		return fmt.Errorf("transfer amount must be greater than zero")
	}

	fromAcc, err := u.financeRepo.GetAccount(fromAccID)
	if err != nil {
		return fmt.Errorf("source account not found: %w", err)
	}
	if fromAcc.Balance < amount {
		// allow overdraft or warn? In personal finances, we allow or warn
	}

	tx := &domain.Transaction{
		AccountID:       fromAccID,
		ToAccountID:     &toAccID,
		Amount:          amount,
		Type:            domain.TxTypeTransfer,
		Note:            note,
		TransactionDate: date,
	}

	return u.financeRepo.CreateTransaction(tx)
}

// CalculateSafeToSpend calculates daily safe spending allowance
func (u *FinanceUsecase) CalculateSafeToSpend() (*domain.SafeToSpendInfo, error) {
	now := time.Now()
	lastDayOfMonth := time.Date(now.Year(), now.Month()+1, 0, 0, 0, 0, 0, time.UTC).Day()
	daysRemaining := (lastDayOfMonth - now.Day()) + 1
	if daysRemaining < 1 {
		daysRemaining = 1
	}

	accounts, _ := u.financeRepo.ListAccounts()
	var totalLiquid int64
	for _, a := range accounts {
		if !a.IsArchived {
			totalLiquid += a.Balance
		}
	}

	budgets, _ := u.financeRepo.ListBudgets(now.Year(), int(now.Month()))
	var totalBudget int64
	var totalSpent int64
	for _, b := range budgets {
		totalBudget += b.Amount
		totalSpent += b.Spent
	}

	var monthlyRemaining int64
	if totalBudget > 0 {
		monthlyRemaining = totalBudget - totalSpent
		if monthlyRemaining < 0 {
			monthlyRemaining = 0
		}
	} else {
		monthlyRemaining = totalLiquid
	}

	dailySafe := monthlyRemaining / int64(daysRemaining)
	weeklySafe := dailySafe * 7

	status := "SAFE"
	if dailySafe <= 0 {
		status = "OVERSPENT"
	} else if totalBudget > 0 && float64(totalSpent)/float64(totalBudget) >= 0.85 {
		status = "WARNING"
	}

	return &domain.SafeToSpendInfo{
		DailySafeAmount:  dailySafe,
		WeeklySafeAmount: weeklySafe,
		MonthlyRemaining: monthlyRemaining,
		DaysRemaining:    daysRemaining,
		SpendingStatus:   status,
	}, nil
}

// CalculateRoundUp calculates spare change rounded up to nearest roundUnit
func (u *FinanceUsecase) CalculateRoundUp(amount int64, roundUnit int64) domain.RoundUpResult {
	if roundUnit <= 0 {
		roundUnit = 5000 // default Rp 5.000
	}
	remainder := amount % roundUnit
	if remainder == 0 {
		return domain.RoundUpResult{
			OriginalAmount: amount,
			RoundedAmount:  amount,
			SpareChange:    0,
		}
	}
	spareChange := roundUnit - remainder
	rounded := amount + spareChange
	return domain.RoundUpResult{
		OriginalAmount: amount,
		RoundedAmount:  rounded,
		SpareChange:    spareChange,
	}
}

