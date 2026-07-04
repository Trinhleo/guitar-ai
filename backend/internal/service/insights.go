package service

import (
	"context"
	"errors"
	"strconv"
	"time"

	"github.com/Trinhleo/guitar-ai/backend/internal/models"
	"github.com/jackc/pgx/v5"
)

func (s *Store) GetLeaderboard(ctx context.Context, currentUserID, instrumentID string, limit int) (models.LeaderboardResponse, error) {
	if limit <= 0 {
		limit = 10
	}
	if limit > 50 {
		limit = 50
	}

	query := `
		SELECT u.id, COALESCE(NULLIF(u.display_name, ''), u.email),
		       AVG(ps.overall_score), MAX(ps.overall_score), COUNT(*)
		FROM practice_sessions ps
		JOIN users u ON u.id = ps.user_id
		WHERE ps.overall_score IS NOT NULL`
	args := []any{}
	if instrumentID != "" {
		query += " AND ps.instrument_id = $1"
		args = append(args, instrumentID)
	}
	query += " GROUP BY u.id, u.display_name, u.email"
	query += " HAVING COUNT(*) >= 1"
	query += " ORDER BY AVG(ps.overall_score) DESC, COUNT(*) DESC"

	if instrumentID != "" {
		query += " LIMIT $2"
		args = append(args, limit)
	} else {
		query += " LIMIT $1"
		args = append(args, limit)
	}

	rows, err := s.Pool.Query(ctx, query, args...)
	if err != nil {
		return models.LeaderboardResponse{}, err
	}
	defer rows.Close()

	items := []models.LeaderboardEntry{}
	rank := 0
	var currentUserRank *int
	for rows.Next() {
		rank++
		var entry models.LeaderboardEntry
		entry.Rank = rank
		if err := rows.Scan(&entry.UserID, &entry.DisplayName, &entry.AverageScore, &entry.BestScore, &entry.SessionCount); err != nil {
			return models.LeaderboardResponse{}, err
		}
		entry.IsCurrentUser = entry.UserID == currentUserID
		if entry.IsCurrentUser {
			r := rank
			currentUserRank = &r
		}
		items = append(items, entry)
	}
	if err := rows.Err(); err != nil {
		return models.LeaderboardResponse{}, err
	}

	return models.LeaderboardResponse{
		Items:           items,
		Instrument:      instrumentID,
		CurrentUserRank: currentUserRank,
	}, nil
}

func (s *Store) GetPracticeInsights(ctx context.Context, userID string) (models.PracticeInsightsResponse, error) {
	var pitchAvg, timingAvg *float64
	err := s.Pool.QueryRow(ctx, `
		SELECT AVG(pm.pitch_accuracy), AVG(pm.timing_accuracy)
		FROM performance_metrics pm
		JOIN practice_sessions ps ON ps.id = pm.session_id
		WHERE ps.user_id = $1`, userID).
		Scan(&pitchAvg, &timingAvg)
	if err != nil {
		return models.PracticeInsightsResponse{}, err
	}

	var sessionsThisWeek int
	weekStart := time.Now().UTC().AddDate(0, 0, -7)
	err = s.Pool.QueryRow(ctx, `
		SELECT COUNT(*) FROM practice_sessions
		WHERE user_id = $1 AND created_at >= $2`, userID, weekStart).
		Scan(&sessionsThisWeek)
	if err != nil {
		return models.PracticeInsightsResponse{}, err
	}

	streak, err := s.practiceStreak(ctx, userID)
	if err != nil {
		return models.PracticeInsightsResponse{}, err
	}

	scoreImprovement, err := s.scoreImprovement(ctx, userID)
	if err != nil {
		return models.PracticeInsightsResponse{}, err
	}

	topInstrument, err := s.topInstrument(ctx, userID)
	if err != nil {
		return models.PracticeInsightsResponse{}, err
	}

	weakArea := detectWeakArea(pitchAvg, timingAvg)
	insights := buildInsightMessages(pitchAvg, timingAvg, streak, sessionsThisWeek, scoreImprovement, topInstrument)

	return models.PracticeInsightsResponse{
		WeakArea:         weakArea,
		PitchAverage:     pitchAvg,
		TimingAverage:    timingAvg,
		PracticeStreak:   streak,
		SessionsThisWeek: sessionsThisWeek,
		ScoreImprovement: scoreImprovement,
		TopInstrument:    topInstrument,
		Insights:         insights,
	}, nil
}

func (s *Store) practiceStreak(ctx context.Context, userID string) (int, error) {
	rows, err := s.Pool.Query(ctx, `
		SELECT DISTINCT DATE(created_at AT TIME ZONE 'UTC') AS day
		FROM practice_sessions
		WHERE user_id = $1
		ORDER BY day DESC`, userID)
	if err != nil {
		return 0, err
	}
	defer rows.Close()

	var days []time.Time
	for rows.Next() {
		var day time.Time
		if err := rows.Scan(&day); err != nil {
			return 0, err
		}
		days = append(days, day.UTC())
	}
	if err := rows.Err(); err != nil {
		return 0, err
	}
	if len(days) == 0 {
		return 0, nil
	}

	today := time.Now().UTC().Truncate(24 * time.Hour)
	yesterday := today.AddDate(0, 0, -1)
	first := days[0].Truncate(24 * time.Hour)
	if !first.Equal(today) && !first.Equal(yesterday) {
		return 0, nil
	}

	streak := 1
	for i := 1; i < len(days); i++ {
		prev := days[i-1].Truncate(24 * time.Hour)
		curr := days[i].Truncate(24 * time.Hour)
		if prev.Sub(curr) == 24*time.Hour {
			streak++
		} else {
			break
		}
	}
	return streak, nil
}

func (s *Store) scoreImprovement(ctx context.Context, userID string) (*float64, error) {
	rows, err := s.Pool.Query(ctx, `
		SELECT overall_score FROM practice_sessions
		WHERE user_id = $1 AND overall_score IS NOT NULL
		ORDER BY created_at DESC
		LIMIT 10`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	scores := []float64{}
	for rows.Next() {
		var score float64
		if err := rows.Scan(&score); err != nil {
			return nil, err
		}
		scores = append(scores, score)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if len(scores) < 4 {
		return nil, nil
	}

	recentCount := 5
	if len(scores) < recentCount {
		recentCount = len(scores)
	}
	recent := scores[:recentCount]
	prior := scores[recentCount:]
	if len(prior) == 0 {
		return nil, nil
	}

	recentAvg := average(recent)
	priorAvg := average(prior)
	delta := recentAvg - priorAvg
	return &delta, nil
}

func (s *Store) topInstrument(ctx context.Context, userID string) (*string, error) {
	var instrumentID *string
	err := s.Pool.QueryRow(ctx, `
		SELECT instrument_id FROM practice_sessions
		WHERE user_id = $1
		GROUP BY instrument_id
		ORDER BY COUNT(*) DESC
		LIMIT 1`, userID).Scan(&instrumentID)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return instrumentID, nil
}

func detectWeakArea(pitchAvg, timingAvg *float64) *string {
	if pitchAvg == nil && timingAvg == nil {
		return nil
	}
	if pitchAvg == nil {
		area := "timing"
		return &area
	}
	if timingAvg == nil {
		area := "pitch"
		return &area
	}
	if *pitchAvg <= *timingAvg-5 {
		area := "pitch"
		return &area
	}
	if *timingAvg <= *pitchAvg-5 {
		area := "timing"
		return &area
	}
	return nil
}

func buildInsightMessages(
	pitchAvg, timingAvg *float64,
	streak, sessionsThisWeek int,
	scoreImprovement *float64,
	topInstrument *string,
) []models.PracticeInsight {
	insights := []models.PracticeInsight{}

	if streak >= 3 {
		insights = append(insights, models.PracticeInsight{
			Category: "streak",
			Message:  "Great consistency — you're on a " + strconv.Itoa(streak) + "-day practice streak!",
			Severity: "info",
		})
	} else if sessionsThisWeek == 0 {
		insights = append(insights, models.PracticeInsight{
			Category: "consistency",
			Message:  "No sessions this week — even 10 minutes of practice helps build muscle memory.",
			Severity: "warning",
		})
	}

	if pitchAvg != nil && *pitchAvg < 75 {
		insights = append(insights, models.PracticeInsight{
			Category: "pitch",
			Message:  "Your average pitch accuracy is below 75% — slow down and use a tuner for each note.",
			Severity: "warning",
		})
	}
	if timingAvg != nil && *timingAvg < 75 {
		insights = append(insights, models.PracticeInsight{
			Category: "timing",
			Message:  "Timing is your weakest area — practice with a metronome at 50–75% tempo.",
			Severity: "warning",
		})
	}

	if scoreImprovement != nil {
		if *scoreImprovement >= 3 {
			insights = append(insights, models.PracticeInsight{
				Category: "improvement",
				Message:  "Your recent scores are trending up — keep pushing!",
				Severity: "info",
			})
		} else if *scoreImprovement <= -3 {
			insights = append(insights, models.PracticeInsight{
				Category: "improvement",
				Message:  "Recent scores dipped — try easier exercises to rebuild confidence.",
				Severity: "warning",
			})
		}
	}

	if topInstrument != nil && len(insights) < 4 {
		insights = append(insights, models.PracticeInsight{
			Category: "instrument",
			Message:  "You practice " + *topInstrument + " most — explore other instruments for variety.",
			Severity: "info",
		})
	}

	if len(insights) == 0 {
		insights = append(insights, models.PracticeInsight{
			Category: "general",
			Message:  "Complete more sessions to unlock personalized practice insights.",
			Severity: "info",
		})
	}

	return insights
}

func average(values []float64) float64 {
	if len(values) == 0 {
		return 0
	}
	sum := 0.0
	for _, v := range values {
		sum += v
	}
	return sum / float64(len(values))
}
