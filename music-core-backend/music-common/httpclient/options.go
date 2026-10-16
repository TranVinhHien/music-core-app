package httpclient

import (
	"net/http"
	"time"

	"github.com/rs/zerolog"
)

// Option configures an HTTP Client.
type Option func(*Client)

// WithBaseURL sets the base URL for all relative request paths.
func WithBaseURL(url string) Option {
	return func(c *Client) {
		c.baseURL = url
	}
}

// WithTimeout sets the request timeout.
func WithTimeout(timeout time.Duration) Option {
	return func(c *Client) {
		c.httpClient.Timeout = timeout
	}
}

// WithRetries sets the number of retry attempts for transient server errors (502, 503, 504).
func WithRetries(retries int) Option {
	return func(c *Client) {
		c.retries = retries
	}
}

// WithDefaultHeader adds a default header to all requests.
func WithDefaultHeader(key, value string) Option {
	return func(c *Client) {
		c.defaultHeaders[key] = value
	}
}

// WithLogger attaches a zerolog logger for tracing external calls.
func WithLogger(logger *zerolog.Logger) Option {
	return func(c *Client) {
		c.logger = logger
	}
}

// WithHTTPClient replaces the underlying http.Client.
func WithHTTPClient(client *http.Client) Option {
	return func(c *Client) {
		c.httpClient = client
	}
}

// RequestOption configures an individual HTTP request.
type RequestOption func(*http.Request)

// WithHeader adds or overrides a header for a single request.
func WithHeader(key, value string) RequestOption {
	return func(req *http.Request) {
		req.Header.Set(key, value)
	}
}

// WithBearerToken sets the Authorization header with a Bearer token.
func WithBearerToken(token string) RequestOption {
	return func(req *http.Request) {
		req.Header.Set("Authorization", "Bearer "+token)
	}
}
