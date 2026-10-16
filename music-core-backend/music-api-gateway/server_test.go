package gateway

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/TranVinhHien/music-core-app/music-core-backend/music-core-gateway/config"
	"github.com/rs/zerolog"
)

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
	server := NewServer(cfg, &logger)

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

func TestProxyRouteForwarding(t *testing.T) {
	// 1. Mock upstream service
	upstreamReceived := false
	upstreamReceivedHeader := ""
	mockUpstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		upstreamReceived = true
		upstreamReceivedHeader = r.Header.Get("X-Request-ID")
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"code":"200","message":"success from upstream"}`))
	}))
	defer mockUpstream.Close()

	// 2. Setup gateway pointing to upstream
	cfg := &config.Config{
		App: config.AppConfig{
			Name: "music-api-gateway",
		},
		HttpServer: config.HttpServerConfig{
			Mode: "test",
		},
		Gateway: config.GatewayConfig{
			Routes: []config.GatewayRouteConfig{
				{
					Prefix:       "/api/v1/mock",
					Target:       mockUpstream.URL,
					AuthRequired: true, // Placeholder auth
				},
			},
		},
	}

	logger := zerolog.Nop()
	server := NewServer(cfg, &logger)

	// 3. Test request
	req, _ := http.NewRequest(http.MethodGet, "/api/v1/mock/test-endpoint", nil)
	req.Header.Set("Authorization", "Bearer sample-token")
	resp := newCloseNotifyingRecorder()

	server.Engine().ServeHTTP(resp, req)

	if resp.Code != http.StatusOK {
		t.Fatalf("expected 200 OK from upstream, got %d", resp.Code)
	}

	if !upstreamReceived {
		t.Fatalf("upstream did not receive proxied request")
	}

	if upstreamReceivedHeader == "" {
		t.Fatalf("expected X-Request-ID to be propagated to upstream")
	}
}

func TestNoRoute(t *testing.T) {
	cfg := &config.Config{
		HttpServer: config.HttpServerConfig{
			Mode: "test",
		},
	}

	logger := zerolog.Nop()
	server := NewServer(cfg, &logger)

	req, _ := http.NewRequest(http.MethodGet, "/unknown-path", nil)
	resp := httptest.NewRecorder()

	server.Engine().ServeHTTP(resp, req)

	if resp.Code != http.StatusNotFound {
		t.Fatalf("expected 404 Not Found, got %d", resp.Code)
	}
}
