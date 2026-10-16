package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// CORSConfig defines configuration options for the CORS middleware.
type CORSConfig struct {
	AllowOrigins []string
	AllowMethods []string
	AllowHeaders []string
}

// DefaultCORSConfig returns a permissive default CORS configuration.
func DefaultCORSConfig() CORSConfig {
	return CORSConfig{
		AllowOrigins: []string{"*"},
		AllowMethods: []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders: []string{"Origin", "Content-Type", "Accept", "Authorization", "X-Request-ID", "X-User-ID", "X-User-Email", "X-User-Roles"},
	}
}

// CORS returns a Gin middleware that handles Cross-Origin Resource Sharing.
func CORS(cfg ...CORSConfig) gin.HandlerFunc {
	config := DefaultCORSConfig()
	if len(cfg) > 0 {
		if len(cfg[0].AllowOrigins) > 0 {
			config.AllowOrigins = cfg[0].AllowOrigins
		}
		if len(cfg[0].AllowMethods) > 0 {
			config.AllowMethods = cfg[0].AllowMethods
		}
		if len(cfg[0].AllowHeaders) > 0 {
			config.AllowHeaders = cfg[0].AllowHeaders
		}
	}

	origins := strings.Join(config.AllowOrigins, ", ")
	methods := strings.Join(config.AllowMethods, ", ")
	headers := strings.Join(config.AllowHeaders, ", ")

	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", origins)
		c.Writer.Header().Set("Access-Control-Allow-Methods", methods)
		c.Writer.Header().Set("Access-Control-Allow-Headers", headers)

		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}
