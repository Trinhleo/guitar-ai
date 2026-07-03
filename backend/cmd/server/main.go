package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/Trinhleo/guitar-ai/backend/internal/api"
	"github.com/Trinhleo/guitar-ai/backend/internal/config"
	"github.com/Trinhleo/guitar-ai/backend/internal/db"
	"github.com/Trinhleo/guitar-ai/backend/internal/migrate"
	"github.com/Trinhleo/guitar-ai/backend/internal/service"
	"github.com/joho/godotenv"
)

func main() {
	_ = godotenv.Load("../.env")
	_ = godotenv.Load(".env")

	cfg := config.Load()
	ctx := context.Background()

	pool, err := db.NewPool(ctx, cfg.ActiveDatabaseURL())
	if err != nil {
		log.Fatalf("database connection failed: %v", err)
	}
	defer pool.Close()

	if len(os.Args) > 1 && os.Args[1] == "migrate" {
		if err := migrate.Run(ctx, pool); err != nil {
			log.Fatalf("migration failed: %v", err)
		}
		fmt.Println("Migration 001 applied")
		return
	}

	store := &service.Store{Pool: pool}
	server := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           api.NewRouter(store),
		ReadHeaderTimeout: 5 * time.Second,
	}

	log.Printf("API listening on http://localhost:%s", cfg.Port)
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("server failed: %v", err)
	}
}
