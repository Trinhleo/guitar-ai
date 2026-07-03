package api_test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/google/uuid"

	"github.com/Trinhleo/guitar-ai/backend/internal/api"
	"github.com/Trinhleo/guitar-ai/backend/internal/config"
	"github.com/Trinhleo/guitar-ai/backend/internal/db"
	"github.com/Trinhleo/guitar-ai/backend/internal/evaluation"
	"github.com/Trinhleo/guitar-ai/backend/internal/migrate"
	"github.com/Trinhleo/guitar-ai/backend/internal/models"
	"github.com/Trinhleo/guitar-ai/backend/internal/service"
)

const contentID = "11111111-1111-1111-1111-111111111111"

func testRouter(t *testing.T) http.Handler {
	t.Helper()
	_ = os.Setenv("GO_ENV", "test")
	_ = os.Setenv("JWT_SECRET", "test-jwt-secret-key")

	cfg := config.Load()
	ctx := context.Background()
	pool, err := db.NewPool(ctx, cfg.ActiveDatabaseURL())
	if err != nil {
		t.Fatalf("db connect: %v", err)
	}
	t.Cleanup(func() { pool.Close() })

	if err := migrate.Run(ctx, pool); err != nil {
		t.Fatalf("migrate: %v", err)
	}

	return api.NewRouter(&service.Store{Pool: pool}, cfg)
}

func uniqueEmail(prefix string) string {
	return prefix + "-" + uuid.NewString() + "@example.com"
}

func registerUser(t *testing.T, router http.Handler, email, password string) models.AuthResponse {
	t.Helper()
	body, _ := json.Marshal(map[string]string{
		"email":    email,
		"password": password,
	})
	req := httptest.NewRequest(http.MethodPost, "/api/auth/register", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusCreated {
		t.Fatalf("register status = %d, body = %s", rec.Code, rec.Body.String())
	}

	var resp models.AuthResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode register: %v", err)
	}
	return resp
}

func authHeader(token string) string {
	return "Bearer " + token
}

func TestHealth(t *testing.T) {
	router := testRouter(t)
	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, want 200", rec.Code)
	}

	var body map[string]string
	if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
		t.Fatalf("decode: %v", err)
	}
	if body["status"] != "ok" {
		t.Fatalf("status = %q, want ok", body["status"])
	}
}

func TestAuthRegisterAndLogin(t *testing.T) {
	router := testRouter(t)
	email := uniqueEmail("student")

	registered := registerUser(t, router, email, "password123")
	if registered.Token == "" || registered.UserID == "" {
		t.Fatalf("expected token and userId, got %+v", registered)
	}

	loginBody, _ := json.Marshal(map[string]string{
		"email":    email,
		"password": "password123",
	})
	loginReq := httptest.NewRequest(http.MethodPost, "/api/auth/login", bytes.NewReader(loginBody))
	loginReq.Header.Set("Content-Type", "application/json")
	loginRec := httptest.NewRecorder()
	router.ServeHTTP(loginRec, loginReq)

	if loginRec.Code != http.StatusOK {
		t.Fatalf("login status = %d, body = %s", loginRec.Code, loginRec.Body.String())
	}
}

func TestAuthRegisterDuplicateEmail(t *testing.T) {
	router := testRouter(t)
	email := uniqueEmail("dup")
	registerUser(t, router, email, "password123")

	body, _ := json.Marshal(map[string]string{
		"email":    email,
		"password": "password456",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/auth/register", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusConflict {
		t.Fatalf("status = %d, want 409", rec.Code)
	}
}

func TestAuthLoginInvalidCredentials(t *testing.T) {
	router := testRouter(t)
	email := uniqueEmail("wrong")
	registerUser(t, router, email, "password123")

	body, _ := json.Marshal(map[string]string{
		"email":    email,
		"password": "badpassword",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/auth/login", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want 401", rec.Code)
	}
}

func TestInstrumentsAPI(t *testing.T) {
	router := testRouter(t)

	t.Run("list", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/instruments", nil)
		rec := httptest.NewRecorder()
		router.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("status = %d, want 200", rec.Code)
		}

		var items []map[string]any
		if err := json.Unmarshal(rec.Body.Bytes(), &items); err != nil {
			t.Fatalf("decode: %v", err)
		}
		if len(items) == 0 || items[0]["id"] != "guitar" {
			t.Fatalf("expected guitar instrument, got %+v", items)
		}
	})

	t.Run("get guitar", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/instruments/guitar", nil)
		rec := httptest.NewRecorder()
		router.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("status = %d, want 200", rec.Code)
		}
	})

	t.Run("not found", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/instruments/unknown", nil)
		rec := httptest.NewRecorder()
		router.ServeHTTP(rec, req)

		if rec.Code != http.StatusNotFound {
			t.Fatalf("status = %d, want 404", rec.Code)
		}
	})
}

func TestContentAPI(t *testing.T) {
	router := testRouter(t)

	t.Run("list", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/content", nil)
		rec := httptest.NewRecorder()
		router.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("status = %d, want 200", rec.Code)
		}
	})

	t.Run("get by id", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/content/"+contentID, nil)
		rec := httptest.NewRecorder()
		router.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("status = %d, want 200", rec.Code)
		}
	})

	t.Run("filter type", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/content?type=lesson", nil)
		rec := httptest.NewRecorder()
		router.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("status = %d, want 200", rec.Code)
		}
	})
}

func TestPracticeAPIRequiresAuth(t *testing.T) {
	router := testRouter(t)

	req := httptest.NewRequest(http.MethodPost, "/api/practice/start/"+contentID, bytes.NewReader([]byte(`{}`)))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want 401", rec.Code)
	}
}

func TestPracticeAPI(t *testing.T) {
	router := testRouter(t)
	auth := registerUser(t, router, uniqueEmail("practice"), "password123")

	startBody, _ := json.Marshal(map[string]string{"instrumentId": "guitar"})
	startReq := httptest.NewRequest(http.MethodPost, "/api/practice/start/"+contentID, bytes.NewReader(startBody))
	startReq.Header.Set("Content-Type", "application/json")
	startReq.Header.Set("Authorization", authHeader(auth.Token))
	startRec := httptest.NewRecorder()
	router.ServeHTTP(startRec, startReq)

	if startRec.Code != http.StatusCreated {
		t.Fatalf("start status = %d, want 201, body = %s", startRec.Code, startRec.Body.String())
	}

	var startResp map[string]string
	if err := json.Unmarshal(startRec.Body.Bytes(), &startResp); err != nil {
		t.Fatalf("decode start: %v", err)
	}
	sessionID := startResp["sessionId"]
	if sessionID == "" {
		t.Fatal("missing sessionId")
	}

	evalBody, _ := json.Marshal(map[string]any{
		"playedNotes": []evaluation.Note{
			{Note: "E4", StartMs: 0, DurationMs: 500},
			{Note: "E4", StartMs: 600, DurationMs: 500},
			{Note: "E4", StartMs: 1200, DurationMs: 500},
		},
	})
	evalReq := httptest.NewRequest(http.MethodPost, "/api/practice/"+sessionID+"/evaluate", bytes.NewReader(evalBody))
	evalReq.Header.Set("Content-Type", "application/json")
	evalReq.Header.Set("Authorization", authHeader(auth.Token))
	evalRec := httptest.NewRecorder()
	router.ServeHTTP(evalRec, evalReq)

	if evalRec.Code != http.StatusOK {
		t.Fatalf("evaluate status = %d, want 200", evalRec.Code)
	}

	var scores evaluation.Scores
	if err := json.Unmarshal(evalRec.Body.Bytes(), &scores); err != nil {
		t.Fatalf("decode scores: %v", err)
	}
	if scores.PitchAccuracy != 100 {
		t.Fatalf("pitch accuracy = %v, want 100", scores.PitchAccuracy)
	}

	resultsReq := httptest.NewRequest(http.MethodGet, "/api/practice/"+sessionID+"/results", nil)
	resultsReq.Header.Set("Authorization", authHeader(auth.Token))
	resultsRec := httptest.NewRecorder()
	router.ServeHTTP(resultsRec, resultsReq)

	if resultsRec.Code != http.StatusOK {
		t.Fatalf("results status = %d, want 200", resultsRec.Code)
	}

	var results map[string]any
	if err := json.Unmarshal(resultsRec.Body.Bytes(), &results); err != nil {
		t.Fatalf("decode results: %v", err)
	}
	if results["metrics"] == nil {
		t.Fatal("expected metrics in results")
	}
}

func TestEvaluateMissingPlayedNotes(t *testing.T) {
	router := testRouter(t)
	auth := registerUser(t, router, uniqueEmail("missing-notes"), "password123")

	startReq := httptest.NewRequest(http.MethodPost, "/api/practice/start/"+contentID, bytes.NewReader([]byte(`{}`)))
	startReq.Header.Set("Content-Type", "application/json")
	startReq.Header.Set("Authorization", authHeader(auth.Token))
	startRec := httptest.NewRecorder()
	router.ServeHTTP(startRec, startReq)

	var startResp map[string]string
	_ = json.Unmarshal(startRec.Body.Bytes(), &startResp)

	evalReq := httptest.NewRequest(http.MethodPost, "/api/practice/"+startResp["sessionId"]+"/evaluate", bytes.NewReader([]byte(`{}`)))
	evalReq.Header.Set("Content-Type", "application/json")
	evalReq.Header.Set("Authorization", authHeader(auth.Token))
	evalRec := httptest.NewRecorder()
	router.ServeHTTP(evalRec, evalReq)

	if evalRec.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want 400", evalRec.Code)
	}
}

func TestPracticeSessionOwnership(t *testing.T) {
	router := testRouter(t)
	owner := registerUser(t, router, uniqueEmail("owner"), "password123")
	other := registerUser(t, router, uniqueEmail("other"), "password123")

	startReq := httptest.NewRequest(http.MethodPost, "/api/practice/start/"+contentID, bytes.NewReader([]byte(`{}`)))
	startReq.Header.Set("Content-Type", "application/json")
	startReq.Header.Set("Authorization", authHeader(owner.Token))
	startRec := httptest.NewRecorder()
	router.ServeHTTP(startRec, startReq)

	var startResp map[string]string
	_ = json.Unmarshal(startRec.Body.Bytes(), &startResp)

	resultsReq := httptest.NewRequest(http.MethodGet, "/api/practice/"+startResp["sessionId"]+"/results", nil)
	resultsReq.Header.Set("Authorization", authHeader(other.Token))
	resultsRec := httptest.NewRecorder()
	router.ServeHTTP(resultsRec, resultsReq)

	if resultsRec.Code != http.StatusNotFound {
		t.Fatalf("status = %d, want 404 for other user's session", resultsRec.Code)
	}
}
