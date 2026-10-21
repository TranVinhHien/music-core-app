package middleware

import (
	"errors"
	"net/http"
	"strings"

	"github.com/TranVinhHien/music-core-app/music-core-backend/music-common/constants"
	commonMW "github.com/TranVinhHien/music-core-app/music-core-backend/music-common/middleware"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-common/response"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-listening-event-service/internal/config"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

type JWTClaims struct {
	UserID    uuid.UUID `json:"user_id"`
	Email     string    `json:"email"`
	UserRoles []string  `json:"user_roles"`
	jwt.RegisteredClaims
}

// AuthMiddleware extracts authentication context.
// In the microservice architecture, API Gateway handles token verification and permission checks,
// injecting X-User-ID, X-User-Email, and X-User-Roles headers.
// If X-User-ID is present, this middleware trusts the Gateway headers.
// If missing, it falls back to direct Bearer JWT validation.
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. Check Gateway injected header first
		userIDStr := strings.TrimSpace(c.GetHeader(constants.HeaderUserID))
		if userIDStr != "" {
			if parsedUUID, err := uuid.Parse(userIDStr); err == nil {
				c.Set(constants.CtxKeyUserID, userIDStr)
				c.Set("user_uuid", parsedUUID)
				if email := strings.TrimSpace(c.GetHeader(constants.HeaderUserEmail)); email != "" {
					c.Set(constants.CtxKeyUserEmail, email)
				}
				c.Next()
				return
			}
		}

		// 2. Fallback to direct Bearer token validation
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			response.Error(c, http.StatusUnauthorized, errors.New("authorization header or gateway context required"))
			c.Abort()
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			response.Error(c, http.StatusUnauthorized, errors.New("invalid authorization header format"))
			c.Abort()
			return
		}

		tokenString := parts[1]
		secret := "change-me-to-a-long-random-secret"
		if config.App != nil && config.App.Token.Secret != "" {
			secret = config.App.Token.Secret
		}

		claims := &JWTClaims{}
		token, err := jwt.ParseWithClaims(tokenString, claims, func(t *jwt.Token) (interface{}, error) {
			if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, errors.New("unexpected signing method")
			}
			return []byte(secret), nil
		})

		if err != nil || !token.Valid || claims.UserID == uuid.Nil {
			response.Error(c, http.StatusUnauthorized, errors.New("invalid or expired token"))
			c.Abort()
			return
		}

		c.Set(constants.CtxKeyUserID, claims.UserID.String())
		c.Set("user_uuid", claims.UserID)
		c.Set(constants.CtxKeyUserEmail, claims.Email)
		c.Next()
	}
}

func RequestUserID(c *gin.Context) (uuid.UUID, bool) {
	return commonMW.GetUserID(c)
}
