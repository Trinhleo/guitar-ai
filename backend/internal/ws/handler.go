package ws

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/Trinhleo/guitar-ai/backend/internal/auth"
	"github.com/Trinhleo/guitar-ai/backend/internal/evaluation"
	"github.com/Trinhleo/guitar-ai/backend/internal/service"
	"github.com/go-chi/chi/v5"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

type Handler struct {
	Store *service.Store
	Auth  *auth.Service
}

type noteMessage struct {
	Type string          `json:"type"`
	Note evaluation.Note `json:"note"`
}

type feedbackMessage struct {
	Type           string  `json:"type"`
	PartialScore   float64 `json:"partialScore"`
	PitchAccuracy  float64 `json:"pitchAccuracy"`
	TimingAccuracy float64 `json:"timingAccuracy"`
	MatchedNotes   int     `json:"matchedNotes"`
	TotalNotes     int     `json:"totalNotes"`
	Message        string  `json:"message"`
}

func (h *Handler) PracticeFeedback(w http.ResponseWriter, r *http.Request) {
	token := strings.TrimSpace(r.URL.Query().Get("token"))
	if token == "" {
		authHeader := r.Header.Get("Authorization")
		if strings.HasPrefix(authHeader, "Bearer ") {
			token = strings.TrimSpace(strings.TrimPrefix(authHeader, "Bearer "))
		}
	}
	if token == "" {
		http.Error(w, "missing token", http.StatusUnauthorized)
		return
	}

	claims, err := h.Auth.ValidateToken(token)
	if err != nil {
		http.Error(w, "invalid token", http.StatusUnauthorized)
		return
	}

	sessionID := chi.URLParam(r, "sessionId")
	session, err := h.Store.GetSessionContext(r.Context(), sessionID, claims.UserID)
	if err != nil {
		http.Error(w, "session not found", http.StatusNotFound)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		return
	}
	defer conn.Close()

	playedNotes := []evaluation.Note{}

	for {
		_, payload, err := conn.ReadMessage()
		if err != nil {
			return
		}

		var msg noteMessage
		if err := json.Unmarshal(payload, &msg); err != nil || msg.Type != "note" {
			continue
		}

		playedNotes = append(playedNotes, msg.Note)
		scores := evaluation.EvaluatePerformance(
			session.ExpectedNotes,
			playedNotes,
			session.InstrumentConfig,
		)

		feedback := feedbackMessage{
			Type:           "feedback",
			PartialScore:   scores.OverallScore,
			PitchAccuracy:  scores.PitchAccuracy,
			TimingAccuracy: scores.TimingAccuracy,
			MatchedNotes:   scores.InstrumentSpecificMetrics.MatchedNotes,
			TotalNotes:     scores.InstrumentSpecificMetrics.TotalNotes,
			Message:        feedbackText(scores),
		}

		if err := conn.WriteJSON(feedback); err != nil {
			return
		}
	}
}

func feedbackText(scores evaluation.Scores) string {
	switch {
	case scores.PitchAccuracy >= 95 && scores.TimingAccuracy >= 95:
		return "Excellent! Keep it up."
	case scores.PitchAccuracy >= 80:
		return "Good pitch — watch your timing."
	case scores.PitchAccuracy >= 50:
		return "Getting there — focus on pitch accuracy."
	default:
		return "Keep practicing — match the expected notes."
	}
}
