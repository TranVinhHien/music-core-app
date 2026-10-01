//go:build integration

package integration

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func request(t *testing.T, method, path string, body any, token string) *httptest.ResponseRecorder {
	t.Helper()
	b, _ := json.Marshal(body)
	req := httptest.NewRequest(method, path, bytes.NewReader(b))
	req.Header.Set("Content-Type", "application/json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	w := httptest.NewRecorder()
	testRouter.ServeHTTP(w, req)
	return w
}

func TestAuthAPIEndToEnd(t *testing.T) {
	email := fmt.Sprintf("integration-%d@example.com", time.Now().UnixNano())
	w := request(t, http.MethodPost, "/api/v1/auth/register", map[string]any{"email": email, "password": "secret123", "full_name": "Integration User"}, "")
	if w.Code != http.StatusCreated {
		t.Fatalf("register %d %s", w.Code, w.Body.String())
	}
	w = request(t, http.MethodPost, "/api/v1/auth/login", map[string]any{"email": email, "password": "secret123"}, "")
	if w.Code != http.StatusOK {
		t.Fatalf("login %d %s", w.Code, w.Body.String())
	}
	var env struct {
		Data struct {
			Token   string `json:"token"`
			Refresh string `json:"refresh_token"`
		} `json:"data"`
	}
	if err := json.Unmarshal(w.Body.Bytes(), &env); err != nil {
		t.Fatal(err)
	}
	if env.Data.Token == "" {
		t.Fatal("missing token")
	}
	w = request(t, http.MethodGet, "/api/v1/auth/me", nil, env.Data.Token)
	if w.Code != http.StatusOK {
		t.Fatalf("me %d %s", w.Code, w.Body.String())
	}
	w = request(t, http.MethodPut, "/api/v1/auth/me", map[string]string{"full_name": "Updated Integration User"}, env.Data.Token)
	if w.Code != http.StatusOK {
		t.Fatalf("update profile %d %s", w.Code, w.Body.String())
	}
	w = request(t, http.MethodPut, "/api/v1/auth/me/password", map[string]string{"old_password": "secret123", "new_password": "newsecret123"}, env.Data.Token)
	if w.Code != http.StatusOK {
		t.Fatalf("update password %d %s", w.Code, w.Body.String())
	}
	w = request(t, http.MethodPost, "/api/v1/auth/login", map[string]any{"email": email, "password": "newsecret123"}, "")
	if w.Code != http.StatusOK {
		t.Fatalf("login after password update %d %s", w.Code, w.Body.String())
	}
	var refreshedSession struct {
		Data struct {
			Token   string `json:"token"`
			Refresh string `json:"refresh_token"`
		} `json:"data"`
	}
	if err := json.Unmarshal(w.Body.Bytes(), &refreshedSession); err != nil {
		t.Fatal(err)
	}
	w = request(t, http.MethodPost, "/api/v1/auth/refresh", map[string]string{"refresh_token": env.Data.Refresh}, "")
	if w.Code != http.StatusUnauthorized {
		t.Fatalf("revoked refresh token status=%d body=%s", w.Code, w.Body.String())
	}
	w = request(t, http.MethodPost, "/api/v1/auth/refresh", map[string]string{"refresh_token": refreshedSession.Data.Refresh}, "")
	if w.Code != http.StatusOK {
		t.Fatalf("refresh new session %d %s", w.Code, w.Body.String())
	}
	w = request(t, http.MethodPost, "/api/v1/auth/logout", map[string]string{"refresh_token": refreshedSession.Data.Refresh}, "")
	if w.Code != http.StatusOK {
		t.Fatalf("logout %d %s", w.Code, w.Body.String())
	}
}

func TestHealthAndUploadAPI(t *testing.T) {
	if w := request(t, http.MethodGet, "/health", nil, ""); w.Code != http.StatusOK {
		t.Fatal(w.Code)
	}
	req := httptest.NewRequest(http.MethodPost, "/api/v1/upload", bytes.NewBufferString(""))
	req.Header.Set("Authorization", "Bearer invalid")
	w := httptest.NewRecorder()
	testRouter.ServeHTTP(w, req)
	if w.Code != http.StatusUnauthorized {
		t.Fatalf("upload auth=%d", w.Code)
	}
}
