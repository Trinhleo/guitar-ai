package auth_test

import (
	"testing"

	"github.com/Trinhleo/guitar-ai/backend/internal/auth"
)

func TestHashAndCheckPassword(t *testing.T) {
	hash, err := auth.HashPassword("password123")
	if err != nil {
		t.Fatalf("hash password: %v", err)
	}
	if !auth.CheckPassword("password123", hash) {
		t.Fatal("expected password to match hash")
	}
	if auth.CheckPassword("wrong-password", hash) {
		t.Fatal("expected wrong password to fail")
	}
}
