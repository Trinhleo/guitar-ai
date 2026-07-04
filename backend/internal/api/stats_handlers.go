package api

import (
	"net/http"
	"strconv"

	"github.com/Trinhleo/guitar-ai/backend/internal/auth"
)

func (h *Handler) ListPracticeHistory(w http.ResponseWriter, r *http.Request) {
	userID, err := auth.UserIDFromRequest(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	limit := 20
	offset := 0
	if value := r.URL.Query().Get("limit"); value != "" {
		if parsed, err := strconv.Atoi(value); err == nil {
			limit = parsed
		}
	}
	if value := r.URL.Query().Get("offset"); value != "" {
		if parsed, err := strconv.Atoi(value); err == nil {
			offset = parsed
		}
	}

	history, err := h.Store.ListPracticeHistory(r.Context(), userID, limit, offset)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list practice history")
		return
	}

	writeJSON(w, http.StatusOK, history)
}

func (h *Handler) GetProgress(w http.ResponseWriter, r *http.Request) {
	userID, err := auth.UserIDFromRequest(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	progress, err := h.Store.GetUserProgress(r.Context(), userID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to get progress")
		return
	}

	writeJSON(w, http.StatusOK, progress)
}

func (h *Handler) GetAchievements(w http.ResponseWriter, r *http.Request) {
	userID, err := auth.UserIDFromRequest(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	achievements, err := h.Store.GetUserAchievements(r.Context(), userID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to get achievements")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{"achievements": achievements})
}

func (h *Handler) GetLeaderboard(w http.ResponseWriter, r *http.Request) {
	userID, err := auth.UserIDFromRequest(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	limit := 10
	if value := r.URL.Query().Get("limit"); value != "" {
		if parsed, err := strconv.Atoi(value); err == nil {
			limit = parsed
		}
	}
	instrument := r.URL.Query().Get("instrument")

	leaderboard, err := h.Store.GetLeaderboard(r.Context(), userID, instrument, limit)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to get leaderboard")
		return
	}

	writeJSON(w, http.StatusOK, leaderboard)
}

func (h *Handler) GetPracticeInsights(w http.ResponseWriter, r *http.Request) {
	userID, err := auth.UserIDFromRequest(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	insights, err := h.Store.GetPracticeInsights(r.Context(), userID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to get practice insights")
		return
	}

	writeJSON(w, http.StatusOK, insights)
}
