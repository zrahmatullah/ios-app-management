package domain

import (
	"time"
)

// AccountType represents the type of financial account.
type AccountType string

const (
	AccountTypeCash    AccountType = "CASH"
	AccountTypeBank    AccountType = "BANK"
	AccountTypeEWallet AccountType = "EWALLET"
)

// TransactionType defines whether a transaction is income, expense, or transfer.
type TransactionType string

const (
	TxTypeIncome   TransactionType = "INCOME"
	TxTypeExpense  TransactionType = "EXPENSE"
	TxTypeTransfer TransactionType = "TRANSFER"
)

// Frequency defines periodicity for recurring items.
type Frequency string

const (
	FreqDaily   Frequency = "DAILY"
	FreqWeekly  Frequency = "WEEKLY"
	FreqMonthly Frequency = "MONTHLY"
)

// GoalPriority indicates priority level.
type GoalPriority string

const (
	PriorityLow    GoalPriority = "LOW"
	PriorityMedium GoalPriority = "MEDIUM"
	PriorityHigh   GoalPriority = "HIGH"
)

// GoalStatus indicates lifecycle state.
type GoalStatus string

const (
	GoalStatusActive    GoalStatus = "ACTIVE"
	GoalStatusCompleted GoalStatus = "COMPLETED"
	GoalStatusPostponed GoalStatus = "POSTPONED"
)

// Account represents a financial account/wallet.
type Account struct {
	ID         string      `json:"id"`
	Name       string      `json:"name"`
	Type       AccountType `json:"type"`
	Balance    int64       `json:"balance"` // In lowest currency unit (e.g. Rupiah or Cents)
	Currency   string      `json:"currency"`
	Color      string      `json:"color"`
	Icon       string      `json:"icon"`
	IsArchived bool        `json:"is_archived"`
	CreatedAt  time.Time   `json:"created_at"`
	UpdatedAt  time.Time   `json:"updated_at"`
}

// Category represents transaction categorization.
type Category struct {
	ID        string          `json:"id"`
	Name      string          `json:"name"`
	Type      TransactionType `json:"type"` // INCOME or EXPENSE
	Icon      string          `json:"icon"`
	Color     string          `json:"color"`
	IsDefault bool            `json:"is_default"`
	CreatedAt time.Time       `json:"created_at"`
	UpdatedAt time.Time       `json:"updated_at"`
}

// Transaction represents a financial ledger entry.
type Transaction struct {
	ID              string          `json:"id"`
	AccountID       string          `json:"account_id"`
	AccountName     string          `json:"account_name,omitempty"`
	ToAccountID     *string         `json:"to_account_id,omitempty"`
	ToAccountName   *string         `json:"to_account_name,omitempty"`
	CategoryID      *string         `json:"category_id,omitempty"`
	CategoryName    *string         `json:"category_name,omitempty"`
	CategoryIcon    *string         `json:"category_icon,omitempty"`
	CategoryColor   *string         `json:"category_color,omitempty"`
	Amount          int64           `json:"amount"` // Absolute value in lowest unit
	Type            TransactionType `json:"type"`
	Note            string          `json:"note"`
	TransactionDate time.Time       `json:"transaction_date"`
	ReceiptPath     string          `json:"receipt_path,omitempty"`
	RecurringRuleID *string         `json:"recurring_rule_id,omitempty"`
	CreatedAt       time.Time       `json:"created_at"`
	UpdatedAt       time.Time       `json:"updated_at"`
}

// RecurringRule represents scheduling template for transactions.
type RecurringRule struct {
	ID           string     `json:"id"`
	Frequency    Frequency  `json:"frequency"`
	Interval     int        `json:"interval"` // e.g. every 1 month
	StartDate    time.Time  `json:"start_date"`
	EndDate      *time.Time `json:"end_date,omitempty"`
	NextRunDate  time.Time  `json:"next_run_date"`
	IsActive     bool       `json:"is_active"`
	TemplateJSON string     `json:"template_json"` // Serialized transaction draft
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`
}

// Budget represents spending caps per category.
type Budget struct {
	ID             string    `json:"id"`
	CategoryID     string    `json:"category_id"`
	CategoryName   string    `json:"category_name,omitempty"`
	CategoryIcon   string    `json:"category_icon,omitempty"`
	CategoryColor  string    `json:"category_color,omitempty"`
	Amount         int64     `json:"amount"`
	Spent          int64     `json:"spent"` // Calculated spent in period
	Period         Frequency `json:"period"`
	StartDate      time.Time `json:"start_date"`
	AlertThreshold float64   `json:"alert_threshold"` // e.g. 0.8 for 80%
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
}

// Savings represents a savings piggy bank/target.
type Savings struct {
	ID            string    `json:"id"`
	Name          string    `json:"name"`
	TargetAmount  int64     `json:"target_amount"`
	CurrentAmount int64     `json:"current_amount"`
	Deadline      time.Time `json:"deadline"`
	Icon          string    `json:"icon"`
	Color         string    `json:"color"`
	Status        string    `json:"status"` // ACTIVE, COMPLETED
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

// SavingsEntry represents money deposited or withdrawn from a savings target.
type SavingsEntry struct {
	ID        string    `json:"id"`
	SavingsID string    `json:"savings_id"`
	AccountID *string   `json:"account_id,omitempty"`
	Amount    int64     `json:"amount"`
	Type      string    `json:"type"` // DEPOSIT, WITHDRAW
	Note      string    `json:"note"`
	EntryDate time.Time `json:"entry_date"`
	CreatedAt time.Time `json:"created_at"`
}

// Goal represents a milestone/life goal.
type Goal struct {
	ID        string       `json:"id"`
	Title     string       `json:"title"`
	Category  string       `json:"category"` // CAREER, HEALTH, LEARNING, FINANCE, PERSONAL
	Deadline  time.Time    `json:"deadline"`
	Priority  GoalPriority `json:"priority"`
	Status    GoalStatus   `json:"status"`
	Progress  float64      `json:"progress"` // 0.0 to 1.0
	Tasks     []GoalTask   `json:"tasks,omitempty"`
	CreatedAt time.Time    `json:"created_at"`
	UpdatedAt time.Time    `json:"updated_at"`
}

// GoalTask represents a subtask/milestone under a goal.
type GoalTask struct {
	ID          string    `json:"id"`
	GoalID      string    `json:"goal_id"`
	Title       string    `json:"title"`
	IsCompleted bool      `json:"is_completed"`
	OrderIndex  int       `json:"order_index"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// Habit represents a habit to build.
type Habit struct {
	ID            string    `json:"id"`
	Title         string    `json:"title"`
	Frequency     Frequency `json:"frequency"`
	StreakCurrent int       `json:"streak_current"`
	StreakLongest int       `json:"streak_longest"`
	Icon          string    `json:"icon"`
	Color         string    `json:"color"`
	IsDoneToday   bool      `json:"is_done_today"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

// HabitLog represents a single log of habit completion.
type HabitLog struct {
	ID         string    `json:"id"`
	HabitID    string    `json:"habit_id"`
	LoggedDate string    `json:"logged_date"` // YYYY-MM-DD
	Status     int       `json:"status"`      // 1 for done
	CreatedAt  time.Time `json:"created_at"`
}

// Event represents a calendar event/reminder.
type Event struct {
	ID              string    `json:"id"`
	Title           string    `json:"title"`
	StartTime       time.Time `json:"start_time"`
	EndTime         time.Time `json:"end_time"`
	Location        string    `json:"location"`
	Color           string    `json:"color"`
	Recurrence      string    `json:"recurrence"` // NONE, DAILY, WEEKLY, MONTHLY
	ReminderMinutes int       `json:"reminder_minutes"`
	IsCompleted     bool      `json:"is_completed"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

// Note represents a journal entry or standalone note.
type Note struct {
	ID         string    `json:"id"`
	Title      string    `json:"title"`
	Content    string    `json:"content"`
	Mood       string    `json:"mood"` // Emoji or identifier
	IsPinned   bool      `json:"is_pinned"`
	IsArchived bool      `json:"is_archived"`
	NoteDate   time.Time `json:"note_date"`
	Tags       []string  `json:"tags,omitempty"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}

// Tag represents a labeling tag.
type Tag struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Color string `json:"color"`
}

// DashboardSummary aggregates key metrics for the home screen.
type DashboardSummary struct {
	TotalBalance       int64              `json:"total_balance"`
	MonthIncome        int64              `json:"month_income"`
	MonthExpense       int64              `json:"month_expense"`
	TopSavings         []Savings          `json:"top_savings"`
	TopGoals           []Goal             `json:"top_goals"`
	TodayEvents        []Event            `json:"today_events"`
	RecentNotes        []Note             `json:"recent_notes"`
	RecentTransactions []Transaction      `json:"recent_transactions"`
	HabitsToday        []Habit            `json:"habits_today"`
}

// FinanceReport represents period financial analytics.
type FinanceReport struct {
	TotalIncome     int64             `json:"total_income"`
	TotalExpense    int64             `json:"total_expense"`
	NetSavings      int64             `json:"net_savings"`
	CategoryExpense map[string]int64  `json:"category_expense"`
	DailyTrend      []DailyTrendPoint `json:"daily_trend"`
}

// DailyTrendPoint represents daily spending/income breakdown.
type DailyTrendPoint struct {
	Date    string `json:"date"` // YYYY-MM-DD
	Income  int64  `json:"income"`
	Expense int64  `json:"expense"`
}

// SavingsProjection provides calculation for reaching savings targets.
type SavingsProjection struct {
	SavingsID               string    `json:"savings_id"`
	TargetAmount            int64     `json:"target_amount"`
	CurrentAmount           int64     `json:"current_amount"`
	RemainingAmount         int64     `json:"remaining_amount"`
	ProgressPercentage      float64   `json:"progress_percentage"`
	DaysRemaining           int       `json:"days_remaining"`
	RecommendedDailyDeposit int64     `json:"recommended_daily_deposit"`
	RecommendedWeeklyDeposit int64    `json:"recommended_weekly_deposit"`
	RecommendedMonthlyDeposit int64   `json:"recommended_monthly_deposit"`
	EstimatedCompletionDate *time.Time `json:"estimated_completion_date"`
}

// SafeToSpendInfo represents daily dynamic spending capacity to prevent overspending
type SafeToSpendInfo struct {
	DailySafeAmount   int64  `json:"daily_safe_amount"`
	WeeklySafeAmount  int64  `json:"weekly_safe_amount"`
	MonthlyRemaining  int64  `json:"monthly_remaining"`
	DaysRemaining     int    `json:"days_remaining"`
	SpendingStatus    string `json:"spending_status"` // SAFE, WARNING, OVERSPENT
}

// RoundUpResult represents spared change from transaction rounding
type RoundUpResult struct {
	OriginalAmount int64 `json:"original_amount"`
	RoundedAmount  int64 `json:"rounded_amount"`
	SpareChange    int64 `json:"spare_change"`
}

