package gateway

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/TranVinhHien/music-core-app/music-core-backend/music-core-gateway/config"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-core-gateway/middlewares"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-core-gateway/permissions"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog"
)

func createTestToken(secret string, userID uuid.UUID, email string, roles []string) string {
	claims := middlewares.GatewayJWTClaims{
		UserID:    userID,
		Email:     email,
		UserRoles: roles,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(1 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tok, _ := token.SignedString([]byte(secret))
	return tok
}

func TestHealthCheck(t *testing.T) {
	cfg := &config.Config{
		App: config.AppConfig{
			Name:    "music-api-gateway",
			Version: "v1.0.0",
		},
		HttpServer: config.HttpServerConfig{
			Mode: "test",
		},
	}

	logger := zerolog.Nop()
	server := NewServer(cfg, &logger, nil)

	req, _ := http.NewRequest(http.MethodGet, "/health", nil)
	resp := httptest.NewRecorder()

	server.Engine().ServeHTTP(resp, req)

	if resp.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", resp.Code)
	}

	var body map[string]interface{}
	if err := json.Unmarshal(resp.Body.Bytes(), &body); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if body["status"] != "OK" {
		t.Fatalf("expected status OK, got %v", body["status"])
	}
}

type closeNotifyingRecorder struct {
	*httptest.ResponseRecorder
	closed chan bool
}

func newCloseNotifyingRecorder() *closeNotifyingRecorder {
	return &closeNotifyingRecorder{
		ResponseRecorder: httptest.NewRecorder(),
		closed:           make(chan bool, 1),
	}
}

func (c *closeNotifyingRecorder) CloseNotify() <-chan bool {
	return c.closed
}

func TestProxyRouteForwardingWithAuthAndPermissions(t *testing.T) {
	testSecret := "super-secret-key-12345"
	testUserID := uuid.New()

	// 1. Mock upstream service
	upstreamReceived := false
	forwardedUserID := ""
	forwardedRoles := ""
	mockUpstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		upstreamReceived = true
		forwardedUserID = r.Header.Get("X-User-ID")
		forwardedRoles = r.Header.Get("X-User-Roles")
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"code":"200","message":"success from upstream"}`))
	}))
	defer mockUpstream.Close()

	// 2. Setup Evaluator with user permissions
	evaluator, _ := permissions.NewEvaluator("")
	if err := evaluator.LoadFromFile("./permissions.json"); err != nil {
		_ = evaluator.LoadFromFile("./config/permissions.json")
	}

	cfg := &config.Config{
		App: config.AppConfig{
			Name: "music-api-gateway",
		},
		HttpServer: config.HttpServerConfig{
			Mode: "test",
		},
		Token: config.TokenConfig{
			Secret: testSecret,
		},
		Gateway: config.GatewayConfig{
			Routes: []config.GatewayRouteConfig{
				{
					Prefix:       "/api/v1/library",
					Target:       mockUpstream.URL,
					AuthRequired: true,
				},
			},
		},
	}

	logger := zerolog.Nop()
	server := NewServer(cfg, &logger, evaluator)

	// 3. Test Authorized User request (JWT contains user_roles: ["user"])
	token := createTestToken(testSecret, testUserID, "user@example.com", []string{"user"})
	req, _ := http.NewRequest(http.MethodGet, "/api/v1/library/playlists", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	resp := newCloseNotifyingRecorder()

	server.Engine().ServeHTTP(resp, req)

	if resp.Code != http.StatusOK {
		t.Fatalf("expected 200 OK from upstream, got %d: %s", resp.Code, resp.Body.String())
	}
	if !upstreamReceived {
		t.Fatalf("upstream was not contacted")
	}
	if forwardedUserID != testUserID.String() {
		t.Fatalf("expected forwarded X-User-ID '%s', got '%s'", testUserID.String(), forwardedUserID)
	}
	if forwardedRoles != "user" {
		t.Fatalf("expected forwarded X-User-Roles 'user', got '%s'", forwardedRoles)
	}
}

func TestProxyRouteUnauthorizedWhenTokenMissing(t *testing.T) {
	evaluator, _ := permissions.NewEvaluator("")
	_ = evaluator.LoadFromFile("./config/permissions.json")

	cfg := &config.Config{
		HttpServer: config.HttpServerConfig{Mode: "test"},
		Token:      config.TokenConfig{Secret: "secret"},
		Gateway: config.GatewayConfig{
			Routes: []config.GatewayRouteConfig{
				{
					Prefix:       "/api/v1/library",
					Target:       "http://localhost:9999",
					AuthRequired: true,
				},
			},
		},
	}

	logger := zerolog.Nop()
	server := NewServer(cfg, &logger, evaluator)

	req, _ := http.NewRequest(http.MethodGet, "/api/v1/library/playlists", nil)
	resp := httptest.NewRecorder()

	server.Engine().ServeHTTP(resp, req)

	if resp.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401 Unauthorized, got %d", resp.Code)
	}
}

func TestProxyRouteForbiddenWhenRoleLacksPermission(t *testing.T) {
	testSecret := "super-secret-key-12345"
	testUserID := uuid.New()

	evaluator, _ := permissions.NewEvaluator("")
	_ = evaluator.LoadFromFile("./config/permissions.json")

	cfg := &config.Config{
		HttpServer: config.HttpServerConfig{Mode: "test"},
		Token:      config.TokenConfig{Secret: testSecret},
		Gateway: config.GatewayConfig{
			Routes: []config.GatewayRouteConfig{
				{
					Prefix:       "/api/v1/admin-only",
					Target:       "http://localhost:9999",
					AuthRequired: true,
				},
			},
		},
	}

	logger := zerolog.Nop()
	server := NewServer(cfg, &logger, evaluator)

	// User role has no permission to /api/v1/admin-only
	token := createTestToken(testSecret, testUserID, "user@example.com", []string{"user"})
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/admin-only/reindex", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	resp := httptest.NewRecorder()

	server.Engine().ServeHTTP(resp, req)

	if resp.Code != http.StatusForbidden {
		t.Fatalf("expected 403 Forbidden, got %d: %s", resp.Code, resp.Body.String())
	}
}

func TestPublicRouteAllowsUnauthenticated(t *testing.T) {
	upstreamReceived := false
	mockUpstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		upstreamReceived = true
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"code":"200","message":"public data"}`))
	}))
	defer mockUpstream.Close()

	evaluator, _ := permissions.NewEvaluator("")
	_ = evaluator.LoadFromFile("./config/permissions.json")

	cfg := &config.Config{
		HttpServer: config.HttpServerConfig{Mode: "test"},
		Gateway: config.GatewayConfig{
			Routes: []config.GatewayRouteConfig{
				{
					Prefix:       "/api/v1/auth",
					Target:       mockUpstream.URL,
					AuthRequired: false,
				},
			},
		},
	}

	logger := zerolog.Nop()
	server := NewServer(cfg, &logger, evaluator)

	// Call public route without any Authorization header
	req, _ := http.NewRequest(http.MethodPost, "/api/v1/auth/login", nil)
	resp := newCloseNotifyingRecorder()

	server.Engine().ServeHTTP(resp, req)

	if resp.Code != http.StatusOK {
		t.Fatalf("expected 200 OK for public route without token, got %d: %s", resp.Code, resp.Body.String())
	}
	if !upstreamReceived {
		t.Fatalf("public route failed to forward to upstream")
	}
}

func TestNoRoute(t *testing.T) {
	cfg := &config.Config{
		HttpServer: config.HttpServerConfig{
			Mode: "test",
		},
	}

	logger := zerolog.Nop()
	server := NewServer(cfg, &logger, nil)

	req, _ := http.NewRequest(http.MethodGet, "/unknown-path", nil)
	resp := httptest.NewRecorder()

	server.Engine().ServeHTTP(resp, req)

	if resp.Code != http.StatusNotFound {
		t.Fatalf("expected 404 Not Found, got %d", resp.Code)
	}
}

