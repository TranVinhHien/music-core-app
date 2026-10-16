package middlewares

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

const (
	RequestIDHeader = "X-Request-ID"
)

// RequestID generates or propagates a unique request ID across incoming and proxied requests.
func RequestID() gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetHeader(RequestIDHeader)
		if requestID == "" {
			requestID = uuid.New().String()
		}
		c.Header(RequestIDHeader, requestID)
		c.Set(RequestIDHeader, requestID)
		c.Request.Header.Set(RequestIDHeader, requestID)
		c.Next()
	}
}
