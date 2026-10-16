package middlewares

import (
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

// AuthMiddleware is a placeholder authentication & authorization middleware for API Gateway.
// NOTE: Detailed authentication & token validation is deferred as requested.
// This middleware currently operates in passthrough mode:
// - It inspects the Authorization header if provided.
// - It can forward or extract user context in the future.
// - It does not reject unauthenticated requests yet, allowing downstream services or future auth modules to handle logic.
func AuthMiddleware(logger *zerolog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")

		if authHeader != "" {
			token := strings.TrimPrefix(authHeader, "Bearer ")
			_ = token // TODO: Validate JWT or query session service when ready
			if logger != nil {
				logger.Debug().
					Str("path", c.Request.URL.Path).
					Msg("[Gateway] AuthMiddleware placeholder: bearer token detected, passing through")
			}
		} else {
			if logger != nil {
				logger.Debug().
					Str("path", c.Request.URL.Path).
					Msg("[Gateway] AuthMiddleware placeholder: no auth header, passing through")
			}
		}

		c.Next()
	}
}
