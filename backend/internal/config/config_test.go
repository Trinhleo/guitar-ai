package config

import (
	"testing"
)

func TestValidateAllowsTestAndDevelopment(t *testing.T) {
	t.Setenv("GO_ENV", "test")
	if err := Load().Validate(); err != nil {
		t.Fatalf("expected no error in test env: %v", err)
	}

	t.Setenv("GO_ENV", "development")
	if err := Load().Validate(); err != nil {
		t.Fatalf("expected no error in development env: %v", err)
	}
}

func TestValidateRejectsWeakSecretInProduction(t *testing.T) {
	t.Setenv("GO_ENV", "production")
	t.Setenv("JWT_SECRET", DefaultJWTSecret)
	if err := Load().Validate(); err == nil {
		t.Fatal("expected error for default JWT secret in production")
	}
}

func TestValidateAllowsCustomSecretInProduction(t *testing.T) {
	t.Setenv("GO_ENV", "production")
	t.Setenv("JWT_SECRET", "super-secure-production-secret")
	if err := Load().Validate(); err != nil {
		t.Fatalf("expected no error with custom secret: %v", err)
	}
}

func TestIsWeakJWTSecret(t *testing.T) {
	if !IsWeakJWTSecret(DefaultJWTSecret) {
		t.Fatal("expected default secret to be weak")
	}
	if !IsWeakJWTSecret("change-me-in-production") {
		t.Fatal("expected example secret to be weak")
	}
	if IsWeakJWTSecret("my-random-secret") {
		t.Fatal("expected custom secret not to be weak")
	}
}
