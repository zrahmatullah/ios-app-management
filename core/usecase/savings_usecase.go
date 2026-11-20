package usecase

import (
	"database/sql"
	"fmt"
	"math"
	"time"

	"lumina/core/domain"
	"lumina/core/repository"
)

type SavingsUsecase struct {
	savingsRepo *repository.SavingsRepository
}

func NewSavingsUsecase(db *sql.DB) *SavingsUsecase {
	return &SavingsUsecase{
		savingsRepo: repository.NewSavingsRepository(db),
	}
}

// CalculateProjection analyzes savings progress, remaining days, and deposits needed
func (u *SavingsUsecase) CalculateProjection(savingsID string) (*domain.SavingsProjection, error) {
	s, err := u.savingsRepo.GetSavings(savingsID)
	if err != nil {
		return nil, fmt.Errorf("savings target not found: %w", err)
	}

	remaining := s.TargetAmount - s.CurrentAmount
	if remaining < 0 {
		remaining = 0
	}

	var progressPct float64
	if s.TargetAmount > 0 {
		progressPct = float64(s.CurrentAmount) / float64(s.TargetAmount)
		if progressPct > 1.0 {
			progressPct = 1.0
		}
	}

	now := time.Now()
	daysRemaining := int(math.Ceil(s.Deadline.Sub(now).Hours() / 24.0))
	if daysRemaining < 1 {
		daysRemaining = 1
	}

	var dailyRec, weeklyRec, monthlyRec int64
	if remaining > 0 {
		dailyRec = int64(math.Ceil(float64(remaining) / float64(daysRemaining)))
		weeksRemaining := float64(daysRemaining) / 7.0
		if weeksRemaining < 1.0 {
			weeksRemaining = 1.0
		}
		weeklyRec = int64(math.Ceil(float64(remaining) / weeksRemaining))

		monthsRemaining := float64(daysRemaining) / 30.0
		if monthsRemaining < 1.0 {
			monthsRemaining = 1.0
		}
		monthlyRec = int64(math.Ceil(float64(remaining) / monthsRemaining))
	}

	// Calculate velocity based on past entries
	entries, _ := u.savingsRepo.ListEntries(savingsID)
	var estimatedCompletion *time.Time
	if len(entries) >= 2 && remaining > 0 {
		firstDate := entries[len(entries)-1].EntryDate
		lastDate := entries[0].EntryDate
		durationDays := lastDate.Sub(firstDate).Hours() / 24.0

		if durationDays >= 1.0 {
			var netSaved int64
			for _, e := range entries {
				if e.Type == "DEPOSIT" {
					netSaved += e.Amount
				} else {
					netSaved -= e.Amount
				}
			}

			if netSaved > 0 {
				dailyRate := float64(netSaved) / durationDays
				if dailyRate > 0 {
					daysNeeded := int(math.Ceil(float64(remaining) / dailyRate))
					estDate := now.AddDate(0, 0, daysNeeded)
					estimatedCompletion = &estDate
				}
			}
		}
	}

	return &domain.SavingsProjection{
		SavingsID:                 s.ID,
		TargetAmount:              s.TargetAmount,
		CurrentAmount:             s.CurrentAmount,
		RemainingAmount:           remaining,
		ProgressPercentage:        progressPct,
		DaysRemaining:             daysRemaining,
		RecommendedDailyDeposit:   dailyRec,
		RecommendedWeeklyDeposit:  weeklyRec,
		RecommendedMonthlyDeposit: monthlyRec,
		EstimatedCompletionDate:   estimatedCompletion,
	}, nil
}
