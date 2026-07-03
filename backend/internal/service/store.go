package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

	"github.com/Trinhleo/guitar-ai/backend/internal/evaluation"
	"github.com/Trinhleo/guitar-ai/backend/internal/models"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

const DemoUserID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"

var (
	ErrNotFound = errors.New("not found")
)

type Store struct {
	Pool *pgxpool.Pool
}

func (s *Store) ListInstruments(ctx context.Context) ([]models.Instrument, error) {
	rows, err := s.Pool.Query(ctx, `SELECT id, name, family, frequency_range_min, frequency_range_max, note_range_low, note_range_high, tuning, techniques, config FROM instruments ORDER BY name`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var instruments []models.Instrument
	for rows.Next() {
		var item models.Instrument
		if err := rows.Scan(&item.ID, &item.Name, &item.Family, &item.FrequencyRangeMin, &item.FrequencyRangeMax, &item.NoteRangeLow, &item.NoteRangeHigh, &item.Tuning, &item.Techniques, &item.Config); err != nil {
			return nil, err
		}
		instruments = append(instruments, item)
	}
	return instruments, rows.Err()
}

func (s *Store) GetInstrument(ctx context.Context, id string) (models.Instrument, error) {
	var item models.Instrument
	err := s.Pool.QueryRow(ctx, `SELECT id, name, family, frequency_range_min, frequency_range_max, note_range_low, note_range_high, tuning, techniques, config FROM instruments WHERE id = $1`, id).
		Scan(&item.ID, &item.Name, &item.Family, &item.FrequencyRangeMin, &item.FrequencyRangeMax, &item.NoteRangeLow, &item.NoteRangeHigh, &item.Tuning, &item.Techniques, &item.Config)
	if errors.Is(err, pgx.ErrNoRows) {
		return item, ErrNotFound
	}
	return item, err
}

func (s *Store) ListContent(ctx context.Context, contentType, instrument string, difficulty *int) ([]models.MusicalContent, error) {
	query := `SELECT id, type, title, instrument_id, difficulty_level, duration_seconds, bpm, key, expected_notes, created_at FROM musical_content WHERE 1=1`
	args := []any{}
	argPos := 1

	if contentType != "" {
		query += fmt.Sprintf(" AND type = $%d", argPos)
		args = append(args, contentType)
		argPos++
	}
	if instrument != "" {
		query += fmt.Sprintf(" AND instrument_id = $%d", argPos)
		args = append(args, instrument)
		argPos++
	}
	if difficulty != nil {
		query += fmt.Sprintf(" AND difficulty_level = $%d", argPos)
		args = append(args, *difficulty)
	}
	query += " ORDER BY title"

	rows, err := s.Pool.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []models.MusicalContent
	for rows.Next() {
		var item models.MusicalContent
		if err := rows.Scan(&item.ID, &item.Type, &item.Title, &item.InstrumentID, &item.DifficultyLevel, &item.DurationSeconds, &item.BPM, &item.Key, &item.ExpectedNotes, &item.CreatedAt); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (s *Store) GetContent(ctx context.Context, id string) (models.MusicalContent, error) {
	var item models.MusicalContent
	err := s.Pool.QueryRow(ctx, `SELECT id, type, title, instrument_id, difficulty_level, duration_seconds, bpm, key, expected_notes, created_at FROM musical_content WHERE id = $1`, id).
		Scan(&item.ID, &item.Type, &item.Title, &item.InstrumentID, &item.DifficultyLevel, &item.DurationSeconds, &item.BPM, &item.Key, &item.ExpectedNotes, &item.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return item, ErrNotFound
	}
	return item, err
}

func (s *Store) StartSession(ctx context.Context, contentID, userID, instrumentID string) (string, error) {
	if _, err := s.GetContent(ctx, contentID); err != nil {
		return "", err
	}

	sessionID := uuid.NewString()
	_, err := s.Pool.Exec(ctx, `INSERT INTO practice_sessions (id, user_id, content_id, instrument_id) VALUES ($1, $2, $3, $4)`, sessionID, userID, contentID, instrumentID)
	return sessionID, err
}

func (s *Store) EvaluateSession(ctx context.Context, sessionID, userID string, playedNotes []evaluation.Note) (evaluation.Scores, error) {
	var expectedNotesRaw, instrumentConfigRaw []byte
	err := s.Pool.QueryRow(ctx, `
		SELECT mc.expected_notes, i.config
		FROM practice_sessions ps
		JOIN musical_content mc ON mc.id = ps.content_id
		JOIN instruments i ON i.id = ps.instrument_id
		WHERE ps.id = $1 AND ps.user_id = $2`, sessionID, userID).Scan(&expectedNotesRaw, &instrumentConfigRaw)
	if errors.Is(err, pgx.ErrNoRows) {
		return evaluation.Scores{}, ErrNotFound
	}
	if err != nil {
		return evaluation.Scores{}, err
	}

	var expectedNotes []evaluation.Note
	if err := json.Unmarshal(expectedNotesRaw, &expectedNotes); err != nil {
		return evaluation.Scores{}, err
	}

	var instrumentConfig evaluation.InstrumentConfig
	if err := json.Unmarshal(instrumentConfigRaw, &instrumentConfig); err != nil {
		return evaluation.Scores{}, err
	}

	scores := evaluation.EvaluatePerformance(expectedNotes, playedNotes, instrumentConfig)

	metricsJSON, err := json.Marshal(scores.InstrumentSpecificMetrics)
	if err != nil {
		return evaluation.Scores{}, err
	}

	_, err = s.Pool.Exec(ctx, `UPDATE practice_sessions SET overall_score = $1 WHERE id = $2`, scores.OverallScore, sessionID)
	if err != nil {
		return evaluation.Scores{}, err
	}

	_, err = s.Pool.Exec(ctx, `
		INSERT INTO performance_metrics
		(session_id, pitch_accuracy, timing_accuracy, technique_score, expression_score, consistency_score, instrument_specific_metrics)
		VALUES ($1, $2, $3, $4, $5, $6, $7)`,
		sessionID, scores.PitchAccuracy, scores.TimingAccuracy, scores.TechniqueScore, scores.ExpressionScore, scores.ConsistencyScore, metricsJSON,
	)
	if err != nil {
		return evaluation.Scores{}, err
	}

	return scores, nil
}

func (s *Store) GetResults(ctx context.Context, sessionID, userID string) (models.ResultsResponse, error) {
	var session models.PracticeSession
	err := s.Pool.QueryRow(ctx, `
		SELECT id, user_id, content_id, instrument_id, overall_score, created_at
		FROM practice_sessions WHERE id = $1 AND user_id = $2`, sessionID, userID).
		Scan(&session.ID, &session.UserID, &session.ContentID, &session.InstrumentID, &session.OverallScore, &session.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return models.ResultsResponse{}, ErrNotFound
	}
	if err != nil {
		return models.ResultsResponse{}, err
	}

	var metrics models.PerformanceMetrics
	err = s.Pool.QueryRow(ctx, `
		SELECT id, session_id, pitch_accuracy, timing_accuracy, technique_score, expression_score, consistency_score, instrument_specific_metrics
		FROM performance_metrics WHERE session_id = $1 ORDER BY id DESC LIMIT 1`, sessionID).
		Scan(&metrics.ID, &metrics.SessionID, &metrics.PitchAccuracy, &metrics.TimingAccuracy, &metrics.TechniqueScore, &metrics.ExpressionScore, &metrics.ConsistencyScore, &metrics.InstrumentSpecificMetrics)
	if errors.Is(err, pgx.ErrNoRows) {
		return models.ResultsResponse{Session: session, Metrics: nil}, nil
	}
	if err != nil {
		return models.ResultsResponse{}, err
	}

	return models.ResultsResponse{Session: session, Metrics: &metrics}, nil
}

type SessionContext struct {
	ExpectedNotes    []evaluation.Note
	InstrumentConfig evaluation.InstrumentConfig
}

func (s *Store) GetSessionContext(ctx context.Context, sessionID, userID string) (SessionContext, error) {
	var expectedNotesRaw, instrumentConfigRaw []byte
	err := s.Pool.QueryRow(ctx, `
		SELECT mc.expected_notes, i.config
		FROM practice_sessions ps
		JOIN musical_content mc ON mc.id = ps.content_id
		JOIN instruments i ON i.id = ps.instrument_id
		WHERE ps.id = $1 AND ps.user_id = $2`, sessionID, userID).
		Scan(&expectedNotesRaw, &instrumentConfigRaw)
	if errors.Is(err, pgx.ErrNoRows) {
		return SessionContext{}, ErrNotFound
	}
	if err != nil {
		return SessionContext{}, err
	}

	var expectedNotes []evaluation.Note
	if err := json.Unmarshal(expectedNotesRaw, &expectedNotes); err != nil {
		return SessionContext{}, err
	}

	var instrumentConfig evaluation.InstrumentConfig
	if err := json.Unmarshal(instrumentConfigRaw, &instrumentConfig); err != nil {
		return SessionContext{}, err
	}

	return SessionContext{
		ExpectedNotes:    expectedNotes,
		InstrumentConfig: instrumentConfig,
	}, nil
}

func (s *Store) ListPracticeHistory(ctx context.Context, userID string, limit, offset int) (models.PracticeHistoryResponse, error) {
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	if offset < 0 {
		offset = 0
	}

	var total int
	if err := s.Pool.QueryRow(ctx, `
		SELECT COUNT(*) FROM practice_sessions WHERE user_id = $1`, userID).
		Scan(&total); err != nil {
		return models.PracticeHistoryResponse{}, err
	}

	rows, err := s.Pool.Query(ctx, `
		SELECT ps.id, ps.content_id, mc.title, mc.type, ps.instrument_id, ps.overall_score, ps.created_at
		FROM practice_sessions ps
		JOIN musical_content mc ON mc.id = ps.content_id
		WHERE ps.user_id = $1
		ORDER BY ps.created_at DESC
		LIMIT $2 OFFSET $3`, userID, limit, offset)
	if err != nil {
		return models.PracticeHistoryResponse{}, err
	}
	defer rows.Close()

	items := []models.PracticeHistoryItem{}
	for rows.Next() {
		var item models.PracticeHistoryItem
		if err := rows.Scan(
			&item.SessionID, &item.ContentID, &item.ContentTitle,
			&item.ContentType, &item.InstrumentID, &item.OverallScore, &item.CreatedAt,
		); err != nil {
			return models.PracticeHistoryResponse{}, err
		}
		items = append(items, item)
	}

	return models.PracticeHistoryResponse{
		Items:  items,
		Limit:  limit,
		Offset: offset,
		Total:  total,
	}, rows.Err()
}

func (s *Store) GetUserProgress(ctx context.Context, userID string) (models.UserProgress, error) {
	var totalSessions, evaluatedCount int
	var avgScore, bestScore *float64
	err := s.Pool.QueryRow(ctx, `
		SELECT
			COUNT(*),
			COUNT(overall_score),
			AVG(overall_score),
			MAX(overall_score)
		FROM practice_sessions
		WHERE user_id = $1`, userID).
		Scan(&totalSessions, &evaluatedCount, &avgScore, &bestScore)
	if err != nil {
		return models.UserProgress{}, err
	}

	rows, err := s.Pool.Query(ctx, `
		SELECT overall_score FROM practice_sessions
		WHERE user_id = $1 AND overall_score IS NOT NULL
		ORDER BY created_at DESC LIMIT 10`, userID)
	if err != nil {
		return models.UserProgress{}, err
	}
	defer rows.Close()

	recentScores := []float64{}
	for rows.Next() {
		var score float64
		if err := rows.Scan(&score); err != nil {
			return models.UserProgress{}, err
		}
		recentScores = append(recentScores, score)
	}
	if err := rows.Err(); err != nil {
		return models.UserProgress{}, err
	}

	typeRows, err := s.Pool.Query(ctx, `
		SELECT mc.type, COUNT(*)
		FROM practice_sessions ps
		JOIN musical_content mc ON mc.id = ps.content_id
		WHERE ps.user_id = $1
		GROUP BY mc.type`, userID)
	if err != nil {
		return models.UserProgress{}, err
	}
	defer typeRows.Close()

	sessionsByType := map[string]int{}
	for typeRows.Next() {
		var contentType string
		var count int
		if err := typeRows.Scan(&contentType, &count); err != nil {
			return models.UserProgress{}, err
		}
		sessionsByType[contentType] = count
	}

	return models.UserProgress{
		TotalSessions:  totalSessions,
		EvaluatedCount: evaluatedCount,
		AverageScore:   avgScore,
		BestScore:      bestScore,
		RecentScores:   recentScores,
		SessionsByType: sessionsByType,
	}, typeRows.Err()
}
