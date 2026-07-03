package config

import (
	"os"
)

type Config struct {
	DatabaseURL     string
	DatabaseURLTest string
	Port            string
}

func Load() Config {
	return Config{
		DatabaseURL:     getenv("DATABASE_URL", "postgresql://guitar:guitar@localhost:5432/guitar_ai"),
		DatabaseURLTest: getenv("DATABASE_URL_TEST", "postgresql://guitar:guitar@localhost:5432/guitar_ai_test"),
		Port:            getenv("PORT", "5000"),
	}
}

func (c Config) ActiveDatabaseURL() string {
	if os.Getenv("GO_ENV") == "test" {
		return c.DatabaseURLTest
	}
	return c.DatabaseURL
}

func getenv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
