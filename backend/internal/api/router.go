package api

import (
	"net/http"

	"github.com/Trinhleo/guitar-ai/backend/internal/service"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func NewRouter(store *service.Store) http.Handler {
	handler := &Handler{Store: store}

	r := chi.NewRouter()
	r.Use(corsMiddleware())
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)

	r.Get("/health", handler.Health)
	r.Route("/api", func(r chi.Router) {
		r.Route("/instruments", func(r chi.Router) {
			r.Get("/", handler.ListInstruments)
			r.Get("/{id}", handler.GetInstrument)
		})
		r.Route("/content", func(r chi.Router) {
			r.Get("/", handler.ListContent)
			r.Get("/{id}", handler.GetContent)
		})
		r.Route("/practice", func(r chi.Router) {
			r.Post("/start/{contentId}", handler.StartPractice)
			r.Post("/{sessionId}/evaluate", handler.EvaluatePractice)
			r.Get("/{sessionId}/results", handler.GetPracticeResults)
		})
	})

	return r
}
