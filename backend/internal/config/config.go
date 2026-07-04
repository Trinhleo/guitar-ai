package config

import (
	"fmt"
	"os"
	"strconv"
	"time"
)

const DefaultJWTSecret = "dev-jwt-secret-change-me"

var weakJWTSecrets = map[string]struct{}{
	DefaultJWTSecret:          {},
	"change-me-in-production": {},
}

type Config struct {
	DatabaseURL     string
	DatabaseURLTest string
	Port            string
	JWTSecret       string
	JWTExpiry       time.Duration
}

func Load() Config {
	expiryHours := 24
	if value := os.Getenv("JWT_EXPIRY_HOURS"); value != "" {
		if parsed, err := strconv.Atoi(value); err == nil && parsed > 0 {
			expiryHours = parsed
		}
	}

	return Config{
		DatabaseURL:     getenv("DATABASE_URL", "postgresql://guitar:guitar@localhost:5432/guitar_ai"),
		DatabaseURLTest: getenv("DATABASE_URL_TEST", "postgresql://guitar:guitar@localhost:5432/guitar_ai_test"),
		Port:            getenv("PORT", "5000"),
		JWTSecret:       getenv("JWT_SECRET", DefaultJWTSecret),
		JWTExpiry:       time.Duration(expiryHours) * time.Hour,
	}
}

func IsWeakJWTSecret(secret string) bool {
	_, ok := weakJWTSecrets[secret]
	return ok
}

func (c Config) Validate() error {
	env := os.Getenv("GO_ENV")
	if env == "test" || env == "development" {
		return nil
	}
	if env == "production" && IsWeakJWTSecret(c.JWTSecret) {
		return fmt.Errorf("JWT_SECRET must be set to a secure value in production")
	}
	return nil
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
