package gateway

import (
	"fmt"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

// ReverseProxyHandler forwards requests to an upstream target service.
type ReverseProxyHandler struct {
	target *url.URL
	proxy  *httputil.ReverseProxy
	logger *zerolog.Logger
}

// NewReverseProxyHandler creates a new reverse proxy handler for the target URL.
func NewReverseProxyHandler(targetURL string, logger *zerolog.Logger) (*ReverseProxyHandler, error) {
	parsedURL, err := url.Parse(targetURL)
	if err != nil {
		return nil, fmt.Errorf("invalid target URL %s: %w", targetURL, err)
	}

	proxy := httputil.NewSingleHostReverseProxy(parsedURL)

	originalDirector := proxy.Director
	proxy.Director = func(req *http.Request) {
		originalDirector(req)
		req.Host = parsedURL.Host
	}

	proxy.ErrorHandler = func(w http.ResponseWriter, req *http.Request, err error) {
		if logger != nil {
			logger.Error().
				Err(err).
				Str("target", targetURL).
				Str("path", req.URL.Path).
				Msg("[Gateway] Upstream service unavailable")
		}
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadGateway)
		_, _ = w.Write([]byte(fmt.Sprintf(`{"code":"502","message":"Bad Gateway: upstream service unavailable (%s)","meta":null,"data":null}`, parsedURL.Host)))
	}

	return &ReverseProxyHandler{
		target: parsedURL,
		proxy:  proxy,
		logger: logger,
	}, nil
}

// Handle returns a Gin HandlerFunc that proxies the HTTP request to the target.
func (h *ReverseProxyHandler) Handle() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Forward client headers
		c.Request.Header.Set("X-Forwarded-Host", c.Request.Host)
		if forwardedFor := c.GetHeader("X-Forwarded-For"); forwardedFor != "" {
			c.Request.Header.Set("X-Forwarded-For", forwardedFor+", "+c.ClientIP())
		} else {
			c.Request.Header.Set("X-Forwarded-For", c.ClientIP())
		}
		if proto := c.GetHeader("X-Forwarded-Proto"); proto == "" {
			scheme := "http"
			if c.Request.TLS != nil {
				scheme = "https"
			}
			c.Request.Header.Set("X-Forwarded-Proto", scheme)
		}

		h.proxy.ServeHTTP(c.Writer, c.Request)
	}
}

// NormalizeURL strips trailing slashes from the given URL.
func NormalizeURL(rawURL string) string {
	return strings.TrimRight(rawURL, "/")
}
