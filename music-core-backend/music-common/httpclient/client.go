package httpclient

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/TranVinhHien/music-core-app/music-core-backend/music-common/constants"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

// HTTPError represents an error returned by an external HTTP API.
type HTTPError struct {
	StatusCode int    `json:"status_code"`
	URL        string `json:"url"`
	Method     string `json:"method"`
	Body       string `json:"body"`
}

func (e *HTTPError) Error() string {
	return fmt.Sprintf("external call failed: %s %s returned status %d: %s", e.Method, e.URL, e.StatusCode, e.Body)
}

// Client is a production-grade external HTTP request handler with retries, context propagation, and JSON helpers.
type Client struct {
	baseURL        string
	httpClient     *http.Client
	defaultHeaders map[string]string
	retries        int
	logger         *zerolog.Logger
}

// NewClient initializes a new external HTTP client.
func NewClient(opts ...Option) *Client {
	c := &Client{
		httpClient: &http.Client{
			Timeout: 15 * time.Second,
		},
		defaultHeaders: make(map[string]string),
		retries:        1,
	}

	for _, opt := range opts {
		opt(c)
	}

	return c
}

// FromGinContext creates a scoped Client that automatically forwards gateway headers
// (X-Request-ID, X-User-ID, X-User-Email, X-User-Roles, Authorization) from the incoming Gin request.
func (c *Client) FromGinContext(ctx *gin.Context) *Client {
	scoped := &Client{
		baseURL:        c.baseURL,
		httpClient:     c.httpClient,
		defaultHeaders: make(map[string]string),
		retries:        c.retries,
		logger:         c.logger,
	}

	for k, v := range c.defaultHeaders {
		scoped.defaultHeaders[k] = v
	}

	if ctx != nil {
		if reqID := ctx.GetHeader(constants.HeaderRequestID); reqID != "" {
			scoped.defaultHeaders[constants.HeaderRequestID] = reqID
		}
		if userID := ctx.GetHeader(constants.HeaderUserID); userID != "" {
			scoped.defaultHeaders[constants.HeaderUserID] = userID
		}
		if email := ctx.GetHeader(constants.HeaderUserEmail); email != "" {
			scoped.defaultHeaders[constants.HeaderUserEmail] = email
		}
		if roles := ctx.GetHeader(constants.HeaderUserRoles); roles != "" {
			scoped.defaultHeaders[constants.HeaderUserRoles] = roles
		}
		if auth := ctx.GetHeader(constants.HeaderAuthorization); auth != "" {
			scoped.defaultHeaders[constants.HeaderAuthorization] = auth
		}
	}

	return scoped
}

// Get performs an HTTP GET request and decodes the response body into target.
func (c *Client) Get(ctx context.Context, path string, target any, opts ...RequestOption) error {
	return c.Do(ctx, http.MethodGet, path, nil, target, opts...)
}

// Post performs an HTTP POST request with a JSON body and decodes the response into target.
func (c *Client) Post(ctx context.Context, path string, body any, target any, opts ...RequestOption) error {
	return c.Do(ctx, http.MethodPost, path, body, target, opts...)
}

// Put performs an HTTP PUT request with a JSON body and decodes the response into target.
func (c *Client) Put(ctx context.Context, path string, body any, target any, opts ...RequestOption) error {
	return c.Do(ctx, http.MethodPut, path, body, target, opts...)
}

// Patch performs an HTTP PATCH request with a JSON body and decodes the response into target.
func (c *Client) Patch(ctx context.Context, path string, body any, target any, opts ...RequestOption) error {
	return c.Do(ctx, http.MethodPatch, path, body, target, opts...)
}

// Delete performs an HTTP DELETE request and decodes the response into target.
func (c *Client) Delete(ctx context.Context, path string, target any, opts ...RequestOption) error {
	return c.Do(ctx, http.MethodDelete, path, nil, target, opts...)
}

// Do executes an HTTP request with retry logic, logging, and automatic JSON marshaling/unmarshaling.
func (c *Client) Do(
	ctx context.Context,
	method string,
	path string,
	body any,
	target any,
	opts ...RequestOption,
) error {
	fullURL := path
	if c.baseURL != "" && !strings.HasPrefix(path, "http://") && !strings.HasPrefix(path, "https://") {
		fullURL = strings.TrimRight(c.baseURL, "/") + "/" + strings.TrimLeft(path, "/")
	}

	var reqBodyBytes []byte
	if body != nil {
		var err error
		reqBodyBytes, err = json.Marshal(body)
		if err != nil {
			return fmt.Errorf("failed to marshal request body: %w", err)
		}
	}

	var resp *http.Response
	var lastErr error
	start := time.Now()

	maxAttempts := c.retries
	if maxAttempts < 1 {
		maxAttempts = 1
	}

	for attempt := 1; attempt <= maxAttempts; attempt++ {
		var bodyReader io.Reader
		if len(reqBodyBytes) > 0 {
			bodyReader = bytes.NewReader(reqBodyBytes)
		}

		req, err := http.NewRequestWithContext(ctx, method, fullURL, bodyReader)
		if err != nil {
			return fmt.Errorf("failed to create http request: %w", err)
		}

		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Accept", "application/json")

		// Apply default headers
		for k, v := range c.defaultHeaders {
			req.Header.Set(k, v)
		}

		// Apply request-level options
		for _, opt := range opts {
			opt(req)
		}

		resp, err = c.httpClient.Do(req)
		if err != nil {
			lastErr = err
			// Check if context canceled or expired
			if ctx.Err() != nil {
				return ctx.Err()
			}
			time.Sleep(time.Duration(attempt*50) * time.Millisecond)
			continue
		}

		// Retry on transient server errors (502, 503, 504)
		if resp.StatusCode == http.StatusBadGateway ||
			resp.StatusCode == http.StatusServiceUnavailable ||
			resp.StatusCode == http.StatusGatewayTimeout {
			_ = resp.Body.Close()
			lastErr = fmt.Errorf("transient error status: %d", resp.StatusCode)
			time.Sleep(time.Duration(attempt*50) * time.Millisecond)
			continue
		}

		// Successfully received a non-transient response
		break
	}

	latency := time.Since(start)

	if c.logger != nil {
		status := 0
		if resp != nil {
			status = resp.StatusCode
		}
		c.logger.Debug().
			Str("method", method).
			Str("url", fullURL).
			Int("status", status).
			Dur("latency", latency).
			Msg("[HTTPClient] External call completed")
	}

	if lastErr != nil && resp == nil {
		return fmt.Errorf("request to %s %s failed after %d attempts: %w", method, fullURL, maxAttempts, lastErr)
	}

	defer resp.Body.Close()

	respBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("failed to read response body: %w", err)
	}

	if resp.StatusCode >= 400 {
		return &HTTPError{
			StatusCode: resp.StatusCode,
			URL:        fullURL,
			Method:     method,
			Body:       string(respBytes),
		}
	}

	if target != nil && len(respBytes) > 0 {
		if err := json.Unmarshal(respBytes, target); err != nil {
			return fmt.Errorf("failed to unmarshal response into target %T: %w (body: %s)", target, err, string(respBytes))
		}
	}

	return nil
}
