package api

import (
	"net/http"

	"github.com/Trinhleo/guitar-ai/backend/internal/auth"
	"github.com/Trinhleo/guitar-ai/backend/internal/config"
	"github.com/Trinhleo/guitar-ai/backend/internal/service"
	"github.com/Trinhleo/guitar-ai/backend/internal/ws"
	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func NewRouter(store *service.Store, cfg config.Config) http.Handler {
	authService := auth.NewService(store.Pool, cfg)
	handler := &Handler{Store: store, Auth: authService}
	wsHandler := &ws.Handler{Store: store, Auth: authService}

	r := chi.NewRouter()
	r.Use(corsMiddleware())
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)

	r.Get("/health", handler.Health)
	r.Get("/ws/practice/{sessionId}", wsHandler.PracticeFeedback)
	r.Route("/api", func(r chi.Router) {
		r.Route("/auth", func(r chi.Router) {
			r.Post("/register", handler.Register)
			r.Post("/login", handler.Login)
		})
		r.Route("/instruments", func(r chi.Router) {
			r.Get("/", handler.ListInstruments)
			r.Get("/{id}", handler.GetInstrument)
		})
		r.Route("/content", func(r chi.Router) {
			r.Get("/", handler.ListContent)
			r.Get("/{id}", handler.GetContent)
		})
		r.Route("/practice", func(r chi.Router) {
			r.Use(AuthMiddleware(authService))
			r.Get("/history", handler.ListPracticeHistory)
			r.Post("/start/{contentId}", handler.StartPractice)
			r.Post("/{sessionId}/evaluate", handler.EvaluatePractice)
			r.Post("/{sessionId}/upload", handler.UploadPracticeAudio)
			r.Get("/{sessionId}/results", handler.GetPracticeResults)
		})
		r.Route("/stats", func(r chi.Router) {
			r.Use(AuthMiddleware(authService))
			r.Get("/progress", handler.GetProgress)
			r.Get("/achievements", handler.GetAchievements)
		})
	})

	return r
}
