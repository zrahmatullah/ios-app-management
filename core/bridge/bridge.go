package bridge

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"strings"
	"sync"
	"time"

	"lumina/core/domain"
	"lumina/core/repository"
	"lumina/core/usecase"
)

var (
	bridgeDB         *sql.DB
	financeRepo      *repository.FinanceRepository
	savingsRepo      *repository.SavingsRepository
	goalsRepo        *repository.GoalsRepository
	calNotesRepo     *repository.CalendarNotesRepository
	financeUsecase   *usecase.FinanceUsecase
	savingsUsecase   *usecase.SavingsUsecase
	bridgeMu         sync.Mutex
)

// ResponseEnvelope is the standard JSON structure returned by all bridge calls
type ResponseEnvelope struct {
	Success bool            `json:"success"`
	Data    json.RawMessage `json:"data,omitempty"`
	Error   string          `json:"error,omitempty"`
}

func successResponse(data interface{}) string {
	bytes, err := json.Marshal(data)
	if err != nil {
		return errorResponse(fmt.Sprintf("failed to serialize response data: %v", err))
	}
	resp := ResponseEnvelope{
		Success: true,
		Data:    bytes,
	}
	resBytes, _ := json.Marshal(resp)
	return string(resBytes)
}

func errorResponse(msg string) string {
	resp := ResponseEnvelope{
		Success: false,
		Error:   msg,
	}
	resBytes, _ := json.Marshal(resp)
	return string(resBytes)
}

// LuminaInit initializes SQLite database at dbPath and runs migrations.
// Exported for gomobile iOS framework.
func LuminaInit(dbPath string) string {
	bridgeMu.Lock()
	defer bridgeMu.Unlock()

	dbInstance, err := repository.InitDB(dbPath)
	if err != nil {
		return errorResponse(fmt.Sprintf("database initialization failed: %v", err))
	}

	bridgeDB = dbInstance.DB()
	financeRepo = repository.NewFinanceRepository(bridgeDB)
	savingsRepo = repository.NewSavingsRepository(bridgeDB)
	goalsRepo = repository.NewGoalsRepository(bridgeDB)
	calNotesRepo = repository.NewCalendarNotesRepository(bridgeDB)
	financeUsecase = usecase.NewFinanceUsecase(bridgeDB)
	savingsUsecase = usecase.NewSavingsUsecase(bridgeDB)

	return successResponse(map[string]interface{}{
		"status":  "initialized",
		"db_path": dbPath,
	})
}

// LuminaDispatch handles requests from Swift frontend via action string & JSON payload.
// Exported for gomobile iOS framework.
func LuminaDispatch(action string, payloadJSON string) string {
	if bridgeDB == nil {
		return errorResponse("database not initialized. Call LuminaInit first.")
	}

	switch action {
	// ================= DASHBOARD =================
	case "get_dashboard_summary":
		summary, err := financeUsecase.GetDashboardSummary()
		if err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(summary)

	// ================= ACCOUNTS =================
	case "list_accounts":
		list, err := financeRepo.ListAccounts()
		if err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(list)

	case "save_account":
		var acc domain.Account
		if err := json.Unmarshal([]byte(payloadJSON), &acc); err != nil {
			return errorResponse("invalid account payload: " + err.Error())
		}
		if err := financeRepo.SaveAccount(&acc); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(acc)

	case "delete_account":
		var payload struct {
			ID string `json:"id"`
		}
		if err := json.Unmarshal([]byte(payloadJSON), &payload); err != nil {
			return errorResponse("invalid payload: " + err.Error())
		}
		if err := financeRepo.DeleteAccount(payload.ID); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(true)

	// ================= CATEGORIES =================
	case "list_categories":
		var filter struct {
			Type *domain.TransactionType `json:"type"`
		}
		if payloadJSON != "" {
			_ = json.Unmarshal([]byte(payloadJSON), &filter)
		}
		list, err := financeRepo.ListCategories(filter.Type)
		if err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(list)

	case "save_category":
		var cat domain.Category
		if err := json.Unmarshal([]byte(payloadJSON), &cat); err != nil {
			return errorResponse("invalid category payload: " + err.Error())
		}
		if err := financeRepo.SaveCategory(&cat); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(cat)

	// ================= TRANSACTIONS =================
	case "create_transaction":
		var tx domain.Transaction
		if err := json.Unmarshal([]byte(payloadJSON), &tx); err != nil {
			return errorResponse("invalid transaction payload: " + err.Error())
		}
		if err := financeRepo.CreateTransaction(&tx); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(tx)

	case "delete_transaction":
		var payload struct {
			ID string `json:"id"`
		}
		if err := json.Unmarshal([]byte(payloadJSON), &payload); err != nil {
			return errorResponse("invalid payload: " + err.Error())
		}
		if err := financeRepo.DeleteTransaction(payload.ID); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(true)

	case "filter_transactions":
		var filter struct {
			StartDate  *string `json:"start_date"`
			EndDate    *string `json:"end_date"`
			CategoryID *string `json:"category_id"`
			AccountID  *string `json:"account_id"`
			Query      *string `json:"query"`
			Limit      int     `json:"limit"`
			Offset     int     `json:"offset"`
		}
		if payloadJSON != "" {
			_ = json.Unmarshal([]byte(payloadJSON), &filter)
		}
		var sDate, eDate *time.Time
		if filter.StartDate != nil && *filter.StartDate != "" {
			t, _ := time.Parse(time.RFC3339, *filter.StartDate)
			sDate = &t
		}
		if filter.EndDate != nil && *filter.EndDate != "" {
			t, _ := time.Parse(time.RFC3339, *filter.EndDate)
			eDate = &t
		}
		list, err := financeRepo.FilterTransactions(sDate, eDate, filter.CategoryID, filter.AccountID, filter.Query, filter.Limit, filter.Offset)
		if err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(list)

	case "transfer":
		var payload struct {
			FromAccountID string    `json:"from_account_id"`
			ToAccountID   string    `json:"to_account_id"`
			Amount        int64     `json:"amount"`
			Note          string    `json:"note"`
			Date          time.Time `json:"date"`
		}
		if err := json.Unmarshal([]byte(payloadJSON), &payload); err != nil {
			return errorResponse("invalid transfer payload: " + err.Error())
		}
		if payload.Date.IsZero() {
			payload.Date = time.Now()
		}
		if err := financeUsecase.Transfer(payload.FromAccountID, payload.ToAccountID, payload.Amount, payload.Note, payload.Date); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(true)

	case "get_finance_report":
		var payload struct {
			StartDate string `json:"start_date"`
			EndDate   string `json:"end_date"`
		}
		if err := json.Unmarshal([]byte(payloadJSON), &payload); err != nil {
			return errorResponse("invalid report payload: " + err.Error())
		}
		sDate, _ := time.Parse(time.RFC3339, payload.StartDate)
		eDate, _ := time.Parse(time.RFC3339, payload.EndDate)
		report, err := financeUsecase.GetFinanceReport(sDate, eDate)
		if err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(report)

	case "get_safe_to_spend":
		info, err := financeUsecase.CalculateSafeToSpend()
		if err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(info)

	case "calculate_round_up":
		var payload struct {
			Amount    int64 `json:"amount"`
			RoundUnit int64 `json:"round_unit"`
		}
		_ = json.Unmarshal([]byte(payloadJSON), &payload)
		res := financeUsecase.CalculateRoundUp(payload.Amount, payload.RoundUnit)
		return successResponse(res)

	// ================= BUDGETS =================
	case "list_budgets":
		var payload struct {
			Year  int `json:"year"`
			Month int `json:"month"`
		}
		_ = json.Unmarshal([]byte(payloadJSON), &payload)
		if payload.Year == 0 {
			now := time.Now()
			payload.Year = now.Year()
			payload.Month = int(now.Month())
		}
		list, err := financeRepo.ListBudgets(payload.Year, payload.Month)
		if err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(list)

	case "save_budget":
		var b domain.Budget
		if err := json.Unmarshal([]byte(payloadJSON), &b); err != nil {
			return errorResponse("invalid budget payload: " + err.Error())
		}
		if err := financeRepo.SaveBudget(&b); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(b)

	case "delete_budget":
		var payload struct {
			ID string `json:"id"`
		}
		_ = json.Unmarshal([]byte(payloadJSON), &payload)
		if err := financeRepo.DeleteBudget(payload.ID); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(true)

	// ================= SAVINGS =================
	case "list_savings":
		list, err := savingsRepo.ListSavings()
		if err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(list)

	case "save_savings":
		var s domain.Savings
		if err := json.Unmarshal([]byte(payloadJSON), &s); err != nil {
			return errorResponse("invalid savings payload: " + err.Error())
		}
		if err := savingsRepo.SaveSavings(&s); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(s)

	case "delete_savings":
		var payload struct {
			ID string `json:"id"`
		}
		_ = json.Unmarshal([]byte(payloadJSON), &payload)
		if err := savingsRepo.DeleteSavings(payload.ID); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(true)

	case "add_savings_entry":
		var entry domain.SavingsEntry
		if err := json.Unmarshal([]byte(payloadJSON), &entry); err != nil {
			return errorResponse("invalid entry payload: " + err.Error())
		}
		if entry.EntryDate.IsZero() {
			entry.EntryDate = time.Now()
		}
		if err := savingsRepo.AddEntry(&entry); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(entry)

	case "list_savings_entries":
		var payload struct {
			SavingsID string `json:"savings_id"`
		}
		_ = json.Unmarshal([]byte(payloadJSON), &payload)
		list, err := savingsRepo.ListEntries(payload.SavingsID)
		if err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(list)

	case "get_savings_projection":
		var payload struct {
			SavingsID string `json:"savings_id"`
		}
		_ = json.Unmarshal([]byte(payloadJSON), &payload)
		proj, err := savingsUsecase.CalculateProjection(payload.SavingsID)
		if err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(proj)

	// ================= GOALS =================
	case "list_goals":
		list, err := goalsRepo.ListGoals()
		if err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(list)

	case "save_goal":
		var g domain.Goal
		if err := json.Unmarshal([]byte(payloadJSON), &g); err != nil {
			return errorResponse("invalid goal payload: " + err.Error())
		}
		if err := goalsRepo.SaveGoal(&g); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(g)

	case "delete_goal":
		var payload struct {
			ID string `json:"id"`
		}
		_ = json.Unmarshal([]byte(payloadJSON), &payload)
		if err := goalsRepo.DeleteGoal(payload.ID); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(true)

	case "save_goal_task":
		var task domain.GoalTask
		if err := json.Unmarshal([]byte(payloadJSON), &task); err != nil {
			return errorResponse("invalid goal task payload: " + err.Error())
		}
		if err := goalsRepo.SaveGoalTask(&task); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(task)

	case "toggle_goal_task":
		var payload struct {
			TaskID string `json:"task_id"`
		}
		_ = json.Unmarshal([]byte(payloadJSON), &payload)
		if err := goalsRepo.ToggleGoalTask(payload.TaskID); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(true)

	case "delete_goal_task":
		var payload struct {
			TaskID string `json:"task_id"`
		}
		_ = json.Unmarshal([]byte(payloadJSON), &payload)
		if err := goalsRepo.DeleteGoalTask(payload.TaskID); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(true)

	// ================= HABITS =================
	case "list_habits":
		list, err := goalsRepo.ListHabits()
		if err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(list)

	case "save_habit":
		var h domain.Habit
		if err := json.Unmarshal([]byte(payloadJSON), &h); err != nil {
			return errorResponse("invalid habit payload: " + err.Error())
		}
		if err := goalsRepo.SaveHabit(&h); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(h)

	case "delete_habit":
		var payload struct {
			ID string `json:"id"`
		}
		_ = json.Unmarshal([]byte(payloadJSON), &payload)
		if err := goalsRepo.DeleteHabit(payload.ID); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(true)

	case "toggle_habit_today":
		var payload struct {
			HabitID string `json:"habit_id"`
		}
		_ = json.Unmarshal([]byte(payloadJSON), &payload)
		isDone, err := goalsRepo.ToggleHabitToday(payload.HabitID)
		if err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(map[string]bool{"is_done_today": isDone})

	// ================= CALENDAR EVENTS =================
	case "list_events":
		var filter struct {
			Start *string `json:"start"`
			End   *string `json:"end"`
		}
		if payloadJSON != "" {
			_ = json.Unmarshal([]byte(payloadJSON), &filter)
		}
		var sTime, eTime *time.Time
		if filter.Start != nil && *filter.Start != "" {
			t, _ := time.Parse(time.RFC3339, *filter.Start)
			sTime = &t
		}
		if filter.End != nil && *filter.End != "" {
			t, _ := time.Parse(time.RFC3339, *filter.End)
			eTime = &t
		}
		list, err := calNotesRepo.ListEvents(sTime, eTime)
		if err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(list)

	case "save_event":
		var e domain.Event
		if err := json.Unmarshal([]byte(payloadJSON), &e); err != nil {
			return errorResponse("invalid event payload: " + err.Error())
		}
		if err := calNotesRepo.SaveEvent(&e); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(e)

	case "delete_event":
		var payload struct {
			ID string `json:"id"`
		}
		_ = json.Unmarshal([]byte(payloadJSON), &payload)
		if err := calNotesRepo.DeleteEvent(payload.ID); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(true)

	// ================= NOTES & JOURNAL =================
	case "list_notes":
		var filter struct {
			Query        *string `json:"query"`
			Tag          *string `json:"tag"`
			PinnedOnly   bool    `json:"pinned_only"`
			ArchivedOnly bool    `json:"archived_only"`
		}
		if payloadJSON != "" {
			_ = json.Unmarshal([]byte(payloadJSON), &filter)
		}
		list, err := calNotesRepo.ListNotes(filter.Query, filter.Tag, filter.PinnedOnly, filter.ArchivedOnly)
		if err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(list)

	case "save_note":
		var n domain.Note
		if err := json.Unmarshal([]byte(payloadJSON), &n); err != nil {
			return errorResponse("invalid note payload: " + err.Error())
		}
		if err := calNotesRepo.SaveNote(&n); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(n)

	case "delete_note":
		var payload struct {
			ID string `json:"id"`
		}
		_ = json.Unmarshal([]byte(payloadJSON), &payload)
		if err := calNotesRepo.DeleteNote(payload.ID); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(true)

	// ================= SETTINGS & DATA =================
	case "get_settings":
		settings, err := calNotesRepo.GetAllSettings()
		if err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(settings)

	case "set_setting":
		var payload struct {
			Key   string `json:"key"`
			Value string `json:"value"`
		}
		if err := json.Unmarshal([]byte(payloadJSON), &payload); err != nil {
			return errorResponse("invalid setting payload: " + err.Error())
		}
		if err := calNotesRepo.SetSetting(payload.Key, payload.Value); err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(true)

	case "export_backup_json":
		jsonStr, err := calNotesRepo.ExportFullBackup()
		if err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(map[string]string{"backup_json": jsonStr})

	case "export_csv":
		csvStr, err := calNotesRepo.ExportTransactionsCSV()
		if err != nil {
			return errorResponse(err.Error())
		}
		return successResponse(map[string]string{"csv_content": csvStr})

	case "wipe_data":
		tables := []string{
			"transactions", "savings_entries", "savings_goals", "budgets",
			"habit_logs", "habits", "goals", "calendar_events", "notes",
			"recurring_rules",
		}
		for _, tbl := range tables {
			if _, err := bridgeDB.Exec("DELETE FROM " + tbl); err != nil {
				return errorResponse(fmt.Sprintf("failed to wipe %s: %v", tbl, err))
			}
		}
		return successResponse(true)

	default:
		return errorResponse(fmt.Sprintf("unknown action: %s", strings.TrimSpace(action)))
	}
}
