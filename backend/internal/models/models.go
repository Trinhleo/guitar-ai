package models

import (
	"encoding/json"
	"time"

	"github.com/Trinhleo/guitar-ai/backend/internal/evaluation"
)

type Instrument struct {
	ID                string          `json:"id"`
	Name              string          `json:"name"`
	Family            string          `json:"family"`
	FrequencyRangeMin *int            `json:"frequency_range_min"`
	FrequencyRangeMax *int            `json:"frequency_range_max"`
	NoteRangeLow      *string         `json:"note_range_low"`
	NoteRangeHigh     *string         `json:"note_range_high"`
	Tuning            json.RawMessage `json:"tuning"`
	Techniques        json.RawMessage `json:"techniques"`
	Config            json.RawMessage `json:"config"`
}

type MusicalContent struct {
	ID              string          `json:"id"`
	Type            string          `json:"type"`
	Title           string          `json:"title"`
	InstrumentID    string          `json:"instrument_id"`
	DifficultyLevel int             `json:"difficulty_level"`
	DurationSeconds *int            `json:"duration_seconds"`
	BPM             *int            `json:"bpm"`
	Key             *string         `json:"key"`
	ExpectedNotes   json.RawMessage `json:"expected_notes"`
	CreatedAt       time.Time       `json:"created_at"`
}

type PracticeSession struct {
	ID           string    `json:"id"`
	UserID       string    `json:"user_id"`
	ContentID    string    `json:"content_id"`
	InstrumentID string    `json:"instrument_id"`
	OverallScore *float64  `json:"overall_score"`
	CreatedAt    time.Time `json:"created_at"`
}

type PerformanceMetrics struct {
	ID                        string          `json:"id"`
	SessionID                 string          `json:"session_id"`
	PitchAccuracy             float64         `json:"pitch_accuracy"`
	TimingAccuracy            float64         `json:"timing_accuracy"`
	TechniqueScore            float64         `json:"technique_score"`
	ExpressionScore           float64         `json:"expression_score"`
	ConsistencyScore          float64         `json:"consistency_score"`
	InstrumentSpecificMetrics json.RawMessage `json:"instrument_specific_metrics"`
}

type StartSessionRequest struct {
	InstrumentID string `json:"instrumentId"`
}

type StartSessionResponse struct {
	SessionID string `json:"sessionId"`
}

type RegisterRequest struct {
	Email       string `json:"email"`
	Password    string `json:"password"`
	DisplayName string `json:"displayName,omitempty"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type AuthResponse struct {
	Token  string `json:"token"`
	UserID string `json:"userId"`
	Email  string `json:"email"`
}

type EvaluateRequest struct {
	PlayedNotes []evaluation.Note `json:"playedNotes"`
}

type ResultsResponse struct {
	Session PracticeSession     `json:"session"`
	Metrics *PerformanceMetrics `json:"metrics"`
}

type PracticeHistoryItem struct {
	SessionID    string    `json:"sessionId"`
	ContentID    string    `json:"contentId"`
	ContentTitle string    `json:"contentTitle"`
	ContentType  string    `json:"contentType"`
	InstrumentID string    `json:"instrumentId"`
	OverallScore *float64  `json:"overallScore"`
	CreatedAt    time.Time `json:"createdAt"`
}

type PracticeHistoryResponse struct {
	Items  []PracticeHistoryItem `json:"items"`
	Limit  int                   `json:"limit"`
	Offset int                   `json:"offset"`
	Total  int                   `json:"total"`
}

type UserProgress struct {
	TotalSessions   int                `json:"totalSessions"`
	EvaluatedCount  int                `json:"evaluatedCount"`
	AverageScore    *float64           `json:"averageScore"`
	BestScore       *float64           `json:"bestScore"`
	RecentScores    []float64          `json:"recentScores"`
	SessionsByType  map[string]int     `json:"sessionsByType"`
}
