package middlewares

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/TranVinhHien/music-core-app/music-core-backend/music-common/constants"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-core-gateway/permissions"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog"
)

// GatewayJWTClaims represents the JWT token payload parsed by API Gateway.
// Contains core user identity: user_id, email, and user_roles.
type GatewayJWTClaims struct {
	UserID    uuid.UUID `json:"user_id"`
	Email     string    `json:"email"`
	UserRoles []string  `json:"user_roles"`
	Roles     []string  `json:"roles,omitempty"` // backward-compatible alias
	jwt.RegisteredClaims
}

// AuthMiddleware performs stateless token verification and permission checking at API Gateway.
// It is applied strictly to routes requiring authorization (auth_required: true).
// It extracts user_id and user_roles directly from the JWT claims, checks permissions
// against permissions.json, and injects context headers (X-User-ID, X-User-Email, X-User-Roles)
// for downstream services without querying any database or remote service.
func AuthMiddleware(
	tokenSecret string,
	permEvaluator *permissions.Evaluator,
	logger *zerolog.Logger,
) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. Extract Bearer token for protected routes
		authHeader := c.GetHeader(constants.HeaderAuthorization)
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code":    "401",
				"message": "Unauthorized: missing Authorization header",
				"meta":    nil,
				"data":    nil,
			})
			c.Abort()
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], constants.BearerPrefix) || strings.TrimSpace(parts[1]) == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code":    "401",
				"message": fmt.Sprintf("Unauthorized: invalid Authorization format, expected %s <token>", constants.BearerPrefix),
				"meta":    nil,
				"data":    nil,
			})
			c.Abort()
			return
		}

		tokenStr := strings.TrimSpace(parts[1])

		// 2. Parse and validate JWT token
		claims := &GatewayJWTClaims{}
		token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
			}
			return []byte(tokenSecret), nil
		})

		if err != nil || !token.Valid {
			if logger != nil {
				logger.Warn().
					Err(err).
					Str("path", c.Request.URL.Path).
					Msg("[Gateway] Token validation failed")
			}
			c.JSON(http.StatusUnauthorized, gin.H{
				"code":    "401",
				"message": "Unauthorized: invalid or expired token",
				"meta":    nil,
				"data":    nil,
			})
			c.Abort()
			return
		}

		// 3. Extract user roles directly from JWT claims (Stateless, no DB call required!)
		roles := claims.UserRoles
		if len(roles) == 0 {
			roles = claims.Roles
		}
		if len(roles) == 0 {
			roles = []string{constants.RoleUser}
		}

		// 4. Check permissions against permissions.json
		if permEvaluator != nil {
			isAllowed := permEvaluator.IsAllowed(roles, c.Request.Method, c.Request.URL.Path)
			if !isAllowed {
				if logger != nil {
					logger.Warn().
						Str(constants.CtxKeyUserID, claims.UserID.String()).
						Strs(constants.CtxKeyUserRoles, roles).
						Str("method", c.Request.Method).
						Str("path", c.Request.URL.Path).
						Msg("[Gateway] Permission denied")
				}
				c.JSON(http.StatusForbidden, gin.H{
					"code":    "403",
					"message": fmt.Sprintf("Forbidden: access denied for method %s on %s", c.Request.Method, c.Request.URL.Path),
					"meta":    nil,
					"data":    nil,
				})
				c.Abort()
				return
			}
		}

		// 5. Inject context and forward headers to downstream microservices
		c.Set(constants.CtxKeyUserID, claims.UserID.String())
		c.Set(constants.CtxKeyEmail, claims.Email)
		c.Set(constants.CtxKeyUserRoles, roles)

		c.Request.Header.Set(constants.HeaderUserID, claims.UserID.String())
		c.Request.Header.Set(constants.HeaderUserEmail, claims.Email)
		c.Request.Header.Set(constants.HeaderUserRoles, strings.Join(roles, ","))

		c.Next()
	}
}
