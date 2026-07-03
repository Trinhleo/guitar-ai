package ws_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/Trinhleo/guitar-ai/backend/internal/api"
	"github.com/Trinhleo/guitar-ai/backend/internal/config"
	"github.com/Trinhleo/guitar-ai/backend/internal/db"
	"github.com/Trinhleo/guitar-ai/backend/internal/evaluation"
	"github.com/Trinhleo/guitar-ai/backend/internal/migrate"
	"github.com/Trinhleo/guitar-ai/backend/internal/service"
	"github.com/Trinhleo/guitar-ai/backend/internal/ws"
	"github.com/gorilla/websocket"
)

const contentID = "11111111-1111-1111-1111-111111111111"

func TestPracticeWebSocketFeedback(t *testing.T) {
	t.Setenv("GO_ENV", "test")
	t.Setenv("JWT_SECRET", "test-jwt-secret-key")

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

	store := &service.Store{Pool: pool}
	router := api.NewRouter(store, cfg)
	server := httptest.NewServer(router)
	t.Cleanup(server.Close)

	email := "ws-" + time.Now().Format("150405.000000") + "@example.com"
	token := registerToken(t, server.URL, email)

	sessionID := startSession(t, server.URL, token)

	wsURL := "ws" + strings.TrimPrefix(server.URL, "http") + "/ws/practice/" + sessionID + "?token=" + token
	conn, _, err := websocket.DefaultDialer.Dial(wsURL, nil)
	if err != nil {
		t.Fatalf("dial ws: %v", err)
	}
	t.Cleanup(func() { conn.Close() })

	msg, _ := json.Marshal(map[string]any{
		"type": "note",
		"note": evaluation.Note{Note: "E4", StartMs: 0, DurationMs: 500},
	})
	if err := conn.WriteMessage(websocket.TextMessage, msg); err != nil {
		t.Fatalf("write ws: %v", err)
	}

	_, payload, err := conn.ReadMessage()
	if err != nil {
		t.Fatalf("read ws: %v", err)
	}

	var feedback map[string]any
	if err := json.Unmarshal(payload, &feedback); err != nil {
		t.Fatalf("decode feedback: %v", err)
	}
	if feedback["type"] != "feedback" {
		t.Fatalf("type = %v, want feedback", feedback["type"])
	}
}

func registerToken(t *testing.T, baseURL, email string) string {
	t.Helper()
	body := `{"email":"` + email + `","password":"password123"}`
	res, err := http.Post(baseURL+"/api/auth/register", "application/json", strings.NewReader(body))
	if err != nil {
		t.Fatalf("register: %v", err)
	}
	defer res.Body.Close()

	var auth map[string]string
	_ = json.NewDecoder(res.Body).Decode(&auth)
	return auth["token"]
}

func startSession(t *testing.T, baseURL, token string) string {
	t.Helper()
	req, _ := http.NewRequest(http.MethodPost, baseURL+"/api/practice/start/"+contentID, strings.NewReader(`{}`))
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("start session: %v", err)
	}
	defer res.Body.Close()

	var body map[string]string
	_ = json.NewDecoder(res.Body).Decode(&body)
	return body["sessionId"]
}

var _ = ws.Handler{}
