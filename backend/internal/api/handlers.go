package api

import (
	"encoding/json"
	"errors"
	"net/http"
	"strconv"

	"github.com/Trinhleo/guitar-ai/backend/internal/auth"
	"github.com/Trinhleo/guitar-ai/backend/internal/evaluation"
	"github.com/Trinhleo/guitar-ai/backend/internal/models"
	"github.com/Trinhleo/guitar-ai/backend/internal/service"
	"github.com/go-chi/chi/v5"
)

type Handler struct {
	Store *service.Store
	Auth  *auth.Service
}

func (h *Handler) Health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) ListInstruments(w http.ResponseWriter, r *http.Request) {
	items, err := h.Store.ListInstruments(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list instruments")
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (h *Handler) GetInstrument(w http.ResponseWriter, r *http.Request) {
	item, err := h.Store.GetInstrument(r.Context(), chi.URLParam(r, "id"))
	if errors.Is(err, service.ErrNotFound) {
		writeError(w, http.StatusNotFound, "Instrument not found")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to get instrument")
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func (h *Handler) ListContent(w http.ResponseWriter, r *http.Request) {
	var difficulty *int
	if value := r.URL.Query().Get("difficulty"); value != "" {
		parsed, err := strconv.Atoi(value)
		if err != nil {
			writeError(w, http.StatusBadRequest, "invalid difficulty")
			return
		}
		difficulty = &parsed
	}

	items, err := h.Store.ListContent(r.Context(), r.URL.Query().Get("type"), r.URL.Query().Get("instrument"), difficulty)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list content")
		return
	}
	writeJSON(w, http.StatusOK, items)
}

func (h *Handler) GetContent(w http.ResponseWriter, r *http.Request) {
	item, err := h.Store.GetContent(r.Context(), chi.URLParam(r, "id"))
	if errors.Is(err, service.ErrNotFound) {
		writeError(w, http.StatusNotFound, "Content not found")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to get content")
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func (h *Handler) ListRecommendations(w http.ResponseWriter, r *http.Request) {
	userID, err := auth.UserIDFromRequest(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	limit := 3
	if value := r.URL.Query().Get("limit"); value != "" {
		if parsed, err := strconv.Atoi(value); err == nil {
			limit = parsed
		}
	}

	items, err := h.Store.GetRecommendations(r.Context(), userID, r.URL.Query().Get("instrument"), limit)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to get recommendations")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

func (h *Handler) StartPractice(w http.ResponseWriter, r *http.Request) {
	userID, err := auth.UserIDFromRequest(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var req models.StartSessionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil && r.ContentLength > 0 {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.InstrumentID == "" {
		req.InstrumentID = "guitar"
	}

	sessionID, err := h.Store.StartSession(r.Context(), chi.URLParam(r, "contentId"), userID, req.InstrumentID)
	if errors.Is(err, service.ErrNotFound) {
		writeError(w, http.StatusNotFound, "Content not found")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to start session")
		return
	}

	writeJSON(w, http.StatusCreated, models.StartSessionResponse{SessionID: sessionID})
}

func (h *Handler) EvaluatePractice(w http.ResponseWriter, r *http.Request) {
	userID, err := auth.UserIDFromRequest(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var req models.EvaluateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.PlayedNotes == nil {
		writeError(w, http.StatusBadRequest, "playedNotes array is required")
		return
	}

	scores, err := h.Store.EvaluateSession(r.Context(), chi.URLParam(r, "sessionId"), userID, req.PlayedNotes)
	if errors.Is(err, service.ErrNotFound) {
		writeError(w, http.StatusNotFound, "Session not found")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to evaluate session")
		return
	}

	writeJSON(w, http.StatusOK, evaluation.ScoresWithHints(scores))
}

func (h *Handler) GetPracticeResults(w http.ResponseWriter, r *http.Request) {
	userID, err := auth.UserIDFromRequest(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	results, err := h.Store.GetResults(r.Context(), chi.URLParam(r, "sessionId"), userID)
	if errors.Is(err, service.ErrNotFound) {
		writeError(w, http.StatusNotFound, "Session not found")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to get results")
		return
	}
	writeJSON(w, http.StatusOK, results)
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}
