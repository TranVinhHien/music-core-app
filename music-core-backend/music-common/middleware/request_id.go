package middleware

import (
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-common/constants"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// RequestID ensures every incoming request has a unique Request ID.
// If the caller or Gateway provides X-Request-ID, it reuses it; otherwise, it generates a new UUIDv4.
// It also sets the X-Request-ID header in the response.
func RequestID() gin.HandlerFunc {
	return func(c *gin.Context) {
		reqID := c.GetHeader(constants.HeaderRequestID)
		if reqID == "" {
			reqID = uuid.New().String()
		}

		c.Set(constants.CtxKeyRequestID, reqID)
		c.Writer.Header().Set(constants.HeaderRequestID, reqID)
		c.Next()
	}
}

// GetRequestID retrieves the Request ID from Gin context.
func GetRequestID(c *gin.Context) string {
	if val, exists := c.Get(constants.CtxKeyRequestID); exists {
		if id, ok := val.(string); ok {
			return id
		}
	}
	return c.GetHeader(constants.HeaderRequestID)
}
