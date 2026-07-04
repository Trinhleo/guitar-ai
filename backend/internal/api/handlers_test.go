package api_test

import (
	"bytes"
	"context"
	"encoding/binary"
	"encoding/json"
	"math"
	"mime/multipart"
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

		hasPiano := false
		for _, item := range items {
			if item["id"] == "piano" {
				hasPiano = true
				break
			}
		}
		if !hasPiano {
			t.Fatal("expected piano instrument in list")
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

func TestPracticeHistoryAndProgress(t *testing.T) {
	router := testRouter(t)
	authResp := registerUser(t, router, uniqueEmail("history"), "password123")

	startReq := httptest.NewRequest(http.MethodPost, "/api/practice/start/"+contentID, bytes.NewReader([]byte(`{}`)))
	startReq.Header.Set("Content-Type", "application/json")
	startReq.Header.Set("Authorization", authHeader(authResp.Token))
	startRec := httptest.NewRecorder()
	router.ServeHTTP(startRec, startReq)

	var startResp map[string]string
	_ = json.Unmarshal(startRec.Body.Bytes(), &startResp)

	evalBody, _ := json.Marshal(map[string]any{
		"playedNotes": []evaluation.Note{
			{Note: "E4", StartMs: 0, DurationMs: 500},
		},
	})
	evalReq := httptest.NewRequest(http.MethodPost, "/api/practice/"+startResp["sessionId"]+"/evaluate", bytes.NewReader(evalBody))
	evalReq.Header.Set("Content-Type", "application/json")
	evalReq.Header.Set("Authorization", authHeader(authResp.Token))
	evalRec := httptest.NewRecorder()
	router.ServeHTTP(evalRec, evalReq)

	historyReq := httptest.NewRequest(http.MethodGet, "/api/practice/history", nil)
	historyReq.Header.Set("Authorization", authHeader(authResp.Token))
	historyRec := httptest.NewRecorder()
	router.ServeHTTP(historyRec, historyReq)

	if historyRec.Code != http.StatusOK {
		t.Fatalf("history status = %d, body = %s", historyRec.Code, historyRec.Body.String())
	}

	var history map[string]any
	if err := json.Unmarshal(historyRec.Body.Bytes(), &history); err != nil {
		t.Fatalf("decode history: %v", err)
	}
	items := history["items"].([]any)
	if len(items) == 0 {
		t.Fatal("expected at least one history item")
	}

	progressReq := httptest.NewRequest(http.MethodGet, "/api/stats/progress", nil)
	progressReq.Header.Set("Authorization", authHeader(authResp.Token))
	progressRec := httptest.NewRecorder()
	router.ServeHTTP(progressRec, progressReq)

	if progressRec.Code != http.StatusOK {
		t.Fatalf("progress status = %d, body = %s", progressRec.Code, progressRec.Body.String())
	}

	var progress map[string]any
	if err := json.Unmarshal(progressRec.Body.Bytes(), &progress); err != nil {
		t.Fatalf("decode progress: %v", err)
	}
	if int(progress["totalSessions"].(float64)) < 1 {
		t.Fatalf("expected totalSessions >= 1, got %+v", progress)
	}
	if _, ok := progress["trends"]; !ok {
		t.Fatal("expected trends in progress response")
	}

	achievementsReq := httptest.NewRequest(http.MethodGet, "/api/stats/achievements", nil)
	achievementsReq.Header.Set("Authorization", authHeader(authResp.Token))
	achievementsRec := httptest.NewRecorder()
	router.ServeHTTP(achievementsRec, achievementsReq)

	if achievementsRec.Code != http.StatusOK {
		t.Fatalf("achievements status = %d, body = %s", achievementsRec.Code, achievementsRec.Body.String())
	}

	var achievementsBody map[string]any
	if err := json.Unmarshal(achievementsRec.Body.Bytes(), &achievementsBody); err != nil {
		t.Fatalf("decode achievements: %v", err)
	}
	achievements := achievementsBody["achievements"].([]any)
	if len(achievements) == 0 {
		t.Fatal("expected achievements list")
	}
}

func TestUploadPracticeAudio(t *testing.T) {
	router := testRouter(t)
	auth := registerUser(t, router, uniqueEmail("upload"), "password123")

	startReq := httptest.NewRequest(http.MethodPost, "/api/practice/start/"+contentID, bytes.NewReader([]byte(`{}`)))
	startReq.Header.Set("Content-Type", "application/json")
	startReq.Header.Set("Authorization", authHeader(auth.Token))
	startRec := httptest.NewRecorder()
	router.ServeHTTP(startRec, startReq)

	var startResp map[string]string
	if err := json.Unmarshal(startRec.Body.Bytes(), &startResp); err != nil {
		t.Fatalf("decode start: %v", err)
	}
	sessionID := startResp["sessionId"]

	wavBytes := sampleWAV(t, 329.63, 0.5)

	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)
	part, err := writer.CreateFormFile("audio", "sample.wav")
	if err != nil {
		t.Fatalf("create form file: %v", err)
	}
	if _, err := part.Write(wavBytes); err != nil {
		t.Fatalf("write wav: %v", err)
	}
	if err := writer.Close(); err != nil {
		t.Fatalf("close writer: %v", err)
	}

	uploadReq := httptest.NewRequest(http.MethodPost, "/api/practice/"+sessionID+"/upload", body)
	uploadReq.Header.Set("Content-Type", writer.FormDataContentType())
	uploadReq.Header.Set("Authorization", authHeader(auth.Token))
	uploadRec := httptest.NewRecorder()
	router.ServeHTTP(uploadRec, uploadReq)

	if uploadRec.Code != http.StatusOK {
		t.Fatalf("upload status = %d, body = %s", uploadRec.Code, uploadRec.Body.String())
	}

	var uploadResp map[string]any
	if err := json.Unmarshal(uploadRec.Body.Bytes(), &uploadResp); err != nil {
		t.Fatalf("decode upload: %v", err)
	}
	if uploadResp["scores"] == nil {
		t.Fatal("expected scores in upload response")
	}
	detected := uploadResp["detectedNotes"].([]any)
	if len(detected) == 0 {
		t.Fatal("expected detected notes from wav upload")
	}
}

func sampleWAV(t *testing.T, freq float64, durationSec float64) []byte {
	t.Helper()

	const sampleRate = 44100
	samples := make([]int16, int(sampleRate*durationSec))
	for i := range samples {
		samples[i] = int16(32767 * math.Sin(2*math.Pi*freq*float64(i)/sampleRate))
	}

	data := make([]byte, 44+len(samples)*2)
	copy(data[0:4], "RIFF")
	binary.LittleEndian.PutUint32(data[4:8], uint32(len(data)-8))
	copy(data[8:12], "WAVE")
	copy(data[12:16], "fmt ")
	binary.LittleEndian.PutUint32(data[16:20], 16)
	binary.LittleEndian.PutUint16(data[20:22], 1)
	binary.LittleEndian.PutUint16(data[22:24], 1)
	binary.LittleEndian.PutUint32(data[24:28], sampleRate)
	binary.LittleEndian.PutUint32(data[28:32], sampleRate*2)
	binary.LittleEndian.PutUint16(data[32:34], 2)
	binary.LittleEndian.PutUint16(data[34:36], 16)
	copy(data[36:40], "data")
	binary.LittleEndian.PutUint32(data[40:44], uint32(len(samples)*2))
	for i, sample := range samples {
		binary.LittleEndian.PutUint16(data[44+i*2:44+i*2+2], uint16(sample))
	}

	return data
}

func TestPracticeResultsIncludesPlayedNotes(t *testing.T) {
	router := testRouter(t)
	auth := registerUser(t, router, uniqueEmail("results-detail"), "password123")

	startBody, _ := json.Marshal(map[string]string{"instrumentId": "guitar"})
	startReq := httptest.NewRequest(http.MethodPost, "/api/practice/start/"+contentID, bytes.NewReader(startBody))
	startReq.Header.Set("Content-Type", "application/json")
	startReq.Header.Set("Authorization", authHeader(auth.Token))
	startRec := httptest.NewRecorder()
	router.ServeHTTP(startRec, startReq)

	var startResp map[string]string
	_ = json.Unmarshal(startRec.Body.Bytes(), &startResp)
	sessionID := startResp["sessionId"]

	played := []evaluation.Note{
		{Note: "E4", StartMs: 0, DurationMs: 500},
		{Note: "E4", StartMs: 600, DurationMs: 500},
	}
	evalBody, _ := json.Marshal(map[string]any{"playedNotes": played})
	evalReq := httptest.NewRequest(http.MethodPost, "/api/practice/"+sessionID+"/evaluate", bytes.NewReader(evalBody))
	evalReq.Header.Set("Content-Type", "application/json")
	evalReq.Header.Set("Authorization", authHeader(auth.Token))
	evalRec := httptest.NewRecorder()
	router.ServeHTTP(evalRec, evalReq)

	resultsReq := httptest.NewRequest(http.MethodGet, "/api/practice/"+sessionID+"/results", nil)
	resultsReq.Header.Set("Authorization", authHeader(auth.Token))
	resultsRec := httptest.NewRecorder()
	router.ServeHTTP(resultsRec, resultsReq)

	if resultsRec.Code != http.StatusOK {
		t.Fatalf("results status = %d, body = %s", resultsRec.Code, resultsRec.Body.String())
	}

	var results map[string]any
	if err := json.Unmarshal(resultsRec.Body.Bytes(), &results); err != nil {
		t.Fatalf("decode results: %v", err)
	}
	if results["contentTitle"] == nil || results["contentTitle"] == "" {
		t.Fatal("expected contentTitle in results")
	}
	playedNotes := results["playedNotes"].([]any)
	if len(playedNotes) != len(played) {
		t.Fatalf("playedNotes len = %d, want %d", len(playedNotes), len(played))
	}
	expectedNotes := results["expectedNotes"].([]any)
	if len(expectedNotes) == 0 {
		t.Fatal("expected expectedNotes in results")
	}
}

func TestEvaluateIncludesTechniqueHints(t *testing.T) {
	router := testRouter(t)
	auth := registerUser(t, router, uniqueEmail("hints"), "password123")

	startReq := httptest.NewRequest(http.MethodPost, "/api/practice/start/"+contentID, bytes.NewReader([]byte(`{}`)))
	startReq.Header.Set("Content-Type", "application/json")
	startReq.Header.Set("Authorization", authHeader(auth.Token))
	startRec := httptest.NewRecorder()
	router.ServeHTTP(startRec, startReq)

	var startResp map[string]string
	_ = json.Unmarshal(startRec.Body.Bytes(), &startResp)

	evalBody, _ := json.Marshal(map[string]any{
		"playedNotes": []evaluation.Note{
			{Note: "E4", StartMs: 0, DurationMs: 500},
		},
	})
	evalReq := httptest.NewRequest(http.MethodPost, "/api/practice/"+startResp["sessionId"]+"/evaluate", bytes.NewReader(evalBody))
	evalReq.Header.Set("Content-Type", "application/json")
	evalReq.Header.Set("Authorization", authHeader(auth.Token))
	evalRec := httptest.NewRecorder()
	router.ServeHTTP(evalRec, evalReq)

	var body map[string]any
	_ = json.Unmarshal(evalRec.Body.Bytes(), &body)
	hints := body["techniqueHints"].([]any)
	if len(hints) == 0 {
		t.Fatal("expected techniqueHints in evaluate response")
	}
}

func TestContentRecommendations(t *testing.T) {
	router := testRouter(t)
	auth := registerUser(t, router, uniqueEmail("recs"), "password123")

	req := httptest.NewRequest(http.MethodGet, "/api/content/recommendations?instrument=guitar", nil)
	req.Header.Set("Authorization", authHeader(auth.Token))
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", rec.Code, rec.Body.String())
	}

	var body map[string]any
	_ = json.Unmarshal(rec.Body.Bytes(), &body)
	items := body["items"].([]any)
	if len(items) == 0 {
		t.Fatal("expected recommendation items")
	}
}
