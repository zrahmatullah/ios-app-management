package repository

import (
	"database/sql"
	"time"

	"lumina/core/domain"
	"github.com/google/uuid"
)

type GoalsRepository struct {
	db *sql.DB
}

func NewGoalsRepository(db *sql.DB) *GoalsRepository {
	return &GoalsRepository{db: db}
}

// ================= GOALS =================

func (r *GoalsRepository) ListGoals() ([]domain.Goal, error) {
	rows, err := r.db.Query(`
		SELECT id, title, category, deadline, priority, status, progress, created_at, updated_at
		FROM goals
		ORDER BY status ASC, deadline ASC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.Goal
	for rows.Next() {
		var g domain.Goal
		var dLine, cAt, uAt string
		if err := rows.Scan(&g.ID, &g.Title, &g.Category, &dLine, &g.Priority, &g.Status, &g.Progress, &cAt, &uAt); err != nil {
			return nil, err
		}
		g.Deadline, _ = time.Parse(time.RFC3339, dLine)
		g.CreatedAt, _ = time.Parse(time.RFC3339, cAt)
		g.UpdatedAt, _ = time.Parse(time.RFC3339, uAt)

		// Fetch tasks
		tasks, _ := r.ListGoalTasks(g.ID)
		g.Tasks = tasks

		list = append(list, g)
	}
	return list, nil
}

func (r *GoalsRepository) SaveGoal(g *domain.Goal) error {
	now := time.Now().UTC().Format(time.RFC3339)
	if g.Priority == "" {
		g.Priority = domain.PriorityMedium
	}
	if g.Status == "" {
		g.Status = domain.GoalStatusActive
	}

	if g.ID == "" {
		g.ID = uuid.New().String()
		_, err := r.db.Exec(`
			INSERT INTO goals (id, title, category, deadline, priority, status, progress, created_at, updated_at)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, g.ID, g.Title, g.Category, g.Deadline.Format(time.RFC3339), g.Priority, g.Status, g.Progress, now, now)
		return err
	}
	_, err := r.db.Exec(`
		UPDATE goals SET title = ?, category = ?, deadline = ?, priority = ?, status = ?, progress = ?, updated_at = ?
		WHERE id = ?
	`, g.Title, g.Category, g.Deadline.Format(time.RFC3339), g.Priority, g.Status, g.Progress, now, g.ID)
	return err
}

func (r *GoalsRepository) DeleteGoal(id string) error {
	_, err := r.db.Exec(`DELETE FROM goals WHERE id = ?`, id)
	return err
}

func (r *GoalsRepository) ListGoalTasks(goalID string) ([]domain.GoalTask, error) {
	rows, err := r.db.Query(`
		SELECT id, goal_id, title, is_completed, order_index, created_at, updated_at
		FROM goal_tasks
		WHERE goal_id = ?
		ORDER BY order_index ASC, created_at ASC
	`, goalID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.GoalTask
	for rows.Next() {
		var t domain.GoalTask
		var isComp int
		var cAt, uAt string
		if err := rows.Scan(&t.ID, &t.GoalID, &t.Title, &isComp, &t.OrderIndex, &cAt, &uAt); err != nil {
			return nil, err
		}
		t.IsCompleted = isComp == 1
		t.CreatedAt, _ = time.Parse(time.RFC3339, cAt)
		t.UpdatedAt, _ = time.Parse(time.RFC3339, uAt)
		list = append(list, t)
	}
	return list, nil
}

func (r *GoalsRepository) SaveGoalTask(task *domain.GoalTask) error {
	now := time.Now().UTC().Format(time.RFC3339)
	isComp := 0
	if task.IsCompleted {
		isComp = 1
	}

	if task.ID == "" {
		task.ID = uuid.New().String()
		_, err := r.db.Exec(`
			INSERT INTO goal_tasks (id, goal_id, title, is_completed, order_index, created_at, updated_at)
			VALUES (?, ?, ?, ?, ?, ?, ?)
		`, task.ID, task.GoalID, task.Title, isComp, task.OrderIndex, now, now)
		if err != nil {
			return err
		}
	} else {
		_, err := r.db.Exec(`
			UPDATE goal_tasks SET title = ?, is_completed = ?, order_index = ?, updated_at = ?
			WHERE id = ?
		`, task.Title, isComp, task.OrderIndex, now, task.ID)
		if err != nil {
			return err
		}
	}

	return r.recalculateGoalProgress(task.GoalID)
}

func (r *GoalsRepository) ToggleGoalTask(taskID string) error {
	var goalID string
	var currentComp int
	err := r.db.QueryRow(`SELECT goal_id, is_completed FROM goal_tasks WHERE id = ?`, taskID).Scan(&goalID, &currentComp)
	if err != nil {
		return err
	}

	newComp := 1
	if currentComp == 1 {
		newComp = 0
	}
	now := time.Now().UTC().Format(time.RFC3339)

	_, err = r.db.Exec(`UPDATE goal_tasks SET is_completed = ?, updated_at = ? WHERE id = ?`, newComp, now, taskID)
	if err != nil {
		return err
	}

	return r.recalculateGoalProgress(goalID)
}

func (r *GoalsRepository) DeleteGoalTask(taskID string) error {
	var goalID string
	_ = r.db.QueryRow(`SELECT goal_id FROM goal_tasks WHERE id = ?`, taskID).Scan(&goalID)
	_, err := r.db.Exec(`DELETE FROM goal_tasks WHERE id = ?`, taskID)
	if err != nil {
		return err
	}
	if goalID != "" {
		return r.recalculateGoalProgress(goalID)
	}
	return nil
}

func (r *GoalsRepository) recalculateGoalProgress(goalID string) error {
	var total, completed int
	err := r.db.QueryRow(`
		SELECT COUNT(*), COALESCE(SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END), 0)
		FROM goal_tasks
		WHERE goal_id = ?
	`, goalID).Scan(&total, &completed)
	if err != nil {
		return err
	}

	var progress float64
	var status string = "ACTIVE"
	if total > 0 {
		progress = float64(completed) / float64(total)
		if completed == total {
			status = "COMPLETED"
		}
	}
	now := time.Now().UTC().Format(time.RFC3339)

	_, err = r.db.Exec(`
		UPDATE goals SET progress = ?, status = ?, updated_at = ? WHERE id = ?
	`, progress, status, now, goalID)
	return err
}

// ================= HABITS =================

func (r *GoalsRepository) ListHabits() ([]domain.Habit, error) {
	today := time.Now().Format("2006-01-02")
	rows, err := r.db.Query(`
		SELECT h.id, h.title, h.frequency, h.streak_current, h.streak_longest, h.icon, h.color,
		       EXISTS(SELECT 1 FROM habit_logs hl WHERE hl.habit_id = h.id AND hl.logged_date = ?) AS is_done_today,
		       h.created_at, h.updated_at
		FROM habits h
		ORDER BY h.created_at ASC
	`, today)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.Habit
	for rows.Next() {
		var h domain.Habit
		var isDone int
		var cAt, uAt string
		if err := rows.Scan(&h.ID, &h.Title, &h.Frequency, &h.StreakCurrent, &h.StreakLongest, &h.Icon, &h.Color, &isDone, &cAt, &uAt); err != nil {
			return nil, err
		}
		h.IsDoneToday = isDone == 1
		h.CreatedAt, _ = time.Parse(time.RFC3339, cAt)
		h.UpdatedAt, _ = time.Parse(time.RFC3339, uAt)
		list = append(list, h)
	}
	return list, nil
}

func (r *GoalsRepository) SaveHabit(h *domain.Habit) error {
	now := time.Now().UTC().Format(time.RFC3339)
	if h.Frequency == "" {
		h.Frequency = domain.FreqDaily
	}
	if h.ID == "" {
		h.ID = uuid.New().String()
		_, err := r.db.Exec(`
			INSERT INTO habits (id, title, frequency, streak_current, streak_longest, icon, color, created_at, updated_at)
			VALUES (?, ?, ?, 0, 0, ?, ?, ?, ?)
		`, h.ID, h.Title, h.Frequency, h.Icon, h.Color, now, now)
		return err
	}
	_, err := r.db.Exec(`
		UPDATE habits SET title = ?, frequency = ?, icon = ?, color = ?, updated_at = ?
		WHERE id = ?
	`, h.Title, h.Frequency, h.Icon, h.Color, now, h.ID)
	return err
}

func (r *GoalsRepository) DeleteHabit(id string) error {
	_, err := r.db.Exec(`DELETE FROM habits WHERE id = ?`, id)
	return err
}

// ToggleHabitToday logs or unlogs habit for today, calculating streaks
func (r *GoalsRepository) ToggleHabitToday(habitID string) (bool, error) {
	today := time.Now().Format("2006-01-02")
	yesterday := time.Now().AddDate(0, 0, -1).Format("2006-01-02")
	now := time.Now().UTC().Format(time.RFC3339)

	var existingLogID string
	err := r.db.QueryRow(`SELECT id FROM habit_logs WHERE habit_id = ? AND logged_date = ?`, habitID, today).Scan(&existingLogID)

	if err == nil && existingLogID != "" {
		// Already done today -> toggle off
		_, _ = r.db.Exec(`DELETE FROM habit_logs WHERE id = ?`, existingLogID)
		// Decrement current streak safely
		_, _ = r.db.Exec(`UPDATE habits SET streak_current = MAX(0, streak_current - 1), updated_at = ? WHERE id = ?`, now, habitID)
		return false, nil
	}

	// Not done today -> log it
	newID := uuid.New().String()
	_, err = r.db.Exec(`
		INSERT INTO habit_logs (id, habit_id, logged_date, status, created_at)
		VALUES (?, ?, ?, 1, ?)
	`, newID, habitID, today, now)
	if err != nil {
		return false, err
	}

	// Check if yesterday was completed
	var yCount int
	_ = r.db.QueryRow(`SELECT COUNT(*) FROM habit_logs WHERE habit_id = ? AND logged_date = ?`, habitID, yesterday).Scan(&yCount)

	var currentStreak, longestStreak int
	_ = r.db.QueryRow(`SELECT streak_current, streak_longest FROM habits WHERE id = ?`, habitID).Scan(&currentStreak, &longestStreak)

	if yCount > 0 {
		currentStreak += 1
	} else {
		currentStreak = 1
	}
	if currentStreak > longestStreak {
		longestStreak = currentStreak
	}

	_, err = r.db.Exec(`
		UPDATE habits SET streak_current = ?, streak_longest = ?, updated_at = ?
		WHERE id = ?
	`, currentStreak, longestStreak, now, habitID)
	if err != nil {
		return false, err
	}

	return true, nil
}
