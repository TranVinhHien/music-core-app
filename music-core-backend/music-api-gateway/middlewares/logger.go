package middlewares

import (
	"time"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

// Logger returns a Gin middleware that records structured HTTP request logs with zerolog.
func Logger(logger *zerolog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		raw := c.Request.URL.RawQuery

		c.Next()

		latency := time.Since(start)
		if raw != "" {
			path = path + "?" + raw
		}

		if logger != nil {
			reqID, _ := c.Get(RequestIDHeader)
			reqIDStr, _ := reqID.(string)

			event := logger.Info()
			status := c.Writer.Status()
			if status >= 500 {
				event = logger.Error()
			} else if status >= 400 {
				event = logger.Warn()
			}

			event.
				Str("request_id", reqIDStr).
				Int("status", status).
				Str("method", c.Request.Method).
				Str("path", path).
				Str("ip", c.ClientIP()).
				Dur("latency", latency).
				Str("user_agent", c.Request.UserAgent()).
				Msg("[Gateway] Request")
		}
	}
}
