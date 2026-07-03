package api

import (
	"errors"
	"io"
	"net/http"

	"github.com/Trinhleo/guitar-ai/backend/internal/audio"
	"github.com/Trinhleo/guitar-ai/backend/internal/auth"
	"github.com/Trinhleo/guitar-ai/backend/internal/evaluation"
	"github.com/Trinhleo/guitar-ai/backend/internal/service"
	"github.com/go-chi/chi/v5"
)

func (h *Handler) UploadPracticeAudio(w http.ResponseWriter, r *http.Request) {
	userID, err := auth.UserIDFromRequest(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	if err := r.ParseMultipartForm(10 << 20); err != nil {
		writeError(w, http.StatusBadRequest, "invalid multipart form")
		return
	}

	file, _, err := r.FormFile("audio")
	if err != nil {
		writeError(w, http.StatusBadRequest, "audio file is required")
		return
	}
	defer file.Close()

	payload, err := io.ReadAll(file)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to read audio")
		return
	}

	wav, err := audio.ParseWAV(payload)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid wav file")
		return
	}

	detected := audio.DetectNotes(wav, 250, 250)
	playedNotes := make([]evaluation.Note, len(detected))
	for i, note := range detected {
		playedNotes[i] = evaluation.Note{
			Note:       note.Note,
			StartMs:    note.StartMs,
			DurationMs: note.DurationMs,
		}
	}

	scores, err := h.Store.EvaluateSession(r.Context(), chi.URLParam(r, "sessionId"), userID, playedNotes)
	if errors.Is(err, service.ErrNotFound) {
		writeError(w, http.StatusNotFound, "Session not found")
		return
	}
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to evaluate audio")
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"detectedNotes": playedNotes,
		"scores":        scores,
	})
}
