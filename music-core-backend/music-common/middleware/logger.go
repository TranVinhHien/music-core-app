package middleware

import (
	"time"

	"github.com/TranVinhHien/music-core-app/music-core-backend/music-common/constants"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

// Logger returns a Gin middleware that logs HTTP requests using zerolog.
func Logger(logger *zerolog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		rawQuery := c.Request.URL.RawQuery

		c.Next()

		if logger == nil {
			return
		}

		latency := time.Since(start)
		statusCode := c.Writer.Status()
		clientIP := c.ClientIP()
		method := c.Request.Method
		reqID := c.GetString(constants.CtxKeyRequestID)
		userID := c.GetString(constants.CtxKeyUserID)

		if rawQuery != "" {
			path = path + "?" + rawQuery
		}

		event := logger.Info()
		if statusCode >= 500 {
			event = logger.Error()
		} else if statusCode >= 400 {
			event = logger.Warn()
		}

		event.
			Int("status", statusCode).
			Str("method", method).
			Str("path", path).
			Str("ip", clientIP).
			Dur("latency", latency).
			Str("request_id", reqID).
			Str("user_id", userID).
			Msg("HTTP Request")
	}
}
