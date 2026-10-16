package middleware

import (
	"strings"

	"github.com/TranVinhHien/music-core-app/music-core-backend/music-common/constants"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-common/response"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// UserContextMiddleware extracts user identity headers injected by API Gateway
// (X-User-ID, X-User-Email, X-User-Roles) and stores them into the Gin context.
func UserContextMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		userIDStr := strings.TrimSpace(c.GetHeader(constants.HeaderUserID))
		email := strings.TrimSpace(c.GetHeader(constants.HeaderUserEmail))
		rolesHeader := strings.TrimSpace(c.GetHeader(constants.HeaderUserRoles))

		if userIDStr != "" {
			c.Set(constants.CtxKeyUserID, userIDStr)
			if parsedUUID, err := uuid.Parse(userIDStr); err == nil {
				c.Set("user_uuid", parsedUUID)
			}
		}

		if email != "" {
			c.Set(constants.CtxKeyUserEmail, email)
		}

		var roles []string
		if rolesHeader != "" {
			rawRoles := strings.Split(rolesHeader, ",")
			for _, r := range rawRoles {
				trimmed := strings.ToLower(strings.TrimSpace(r))
				if trimmed != "" {
					roles = append(roles, trimmed)
				}
			}
		}
		if len(roles) == 0 && userIDStr != "" {
			roles = []string{constants.RoleUser}
		}
		c.Set(constants.CtxKeyUserRoles, roles)

		c.Next()
	}
}

// GetUserID retrieves the authenticated User's UUID from the Gin context.
func GetUserID(c *gin.Context) (uuid.UUID, bool) {
	if val, exists := c.Get("user_uuid"); exists {
		if uid, ok := val.(uuid.UUID); ok {
			return uid, true
		}
	}

	if val, exists := c.Get(constants.CtxKeyUserID); exists {
		if uidStr, ok := val.(string); ok {
			if uid, err := uuid.Parse(uidStr); err == nil {
				return uid, true
			}
		}
	}

	rawHeader := c.GetHeader(constants.HeaderUserID)
	if rawHeader != "" {
		if uid, err := uuid.Parse(rawHeader); err == nil {
			return uid, true
		}
	}

	return uuid.Nil, false
}

// MustGetUserID returns the user UUID or panics if not present (use only in authenticated routes).
func MustGetUserID(c *gin.Context) uuid.UUID {
	uid, ok := GetUserID(c)
	if !ok {
		panic("user_id not found in context")
	}
	return uid
}

// GetUserEmail retrieves the authenticated User's email from the Gin context.
func GetUserEmail(c *gin.Context) string {
	if val, exists := c.Get(constants.CtxKeyUserEmail); exists {
		if email, ok := val.(string); ok {
			return email
		}
	}
	return c.GetHeader(constants.HeaderUserEmail)
}

// GetUserRoles retrieves the list of user roles from the Gin context.
func GetUserRoles(c *gin.Context) []string {
	if val, exists := c.Get(constants.CtxKeyUserRoles); exists {
		if roles, ok := val.([]string); ok {
			return roles
		}
	}

	rolesHeader := c.GetHeader(constants.HeaderUserRoles)
	if rolesHeader != "" {
		var roles []string
		for _, r := range strings.Split(rolesHeader, ",") {
			trimmed := strings.ToLower(strings.TrimSpace(r))
			if trimmed != "" {
				roles = append(roles, trimmed)
			}
		}
		return roles
	}

	return []string{}
}

// HasRole checks if the current user possesses a specific role.
func HasRole(c *gin.Context, targetRole string) bool {
	targetRole = strings.ToLower(strings.TrimSpace(targetRole))
	roles := GetUserRoles(c)
	for _, r := range roles {
		if r == targetRole || r == constants.RoleAdmin {
			return true
		}
	}
	return false
}

// RequireAuth middleware ensures that a valid user_id is present.
func RequireAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		_, ok := GetUserID(c)
		if !ok {
			response.Unauthorized(c, "Authentication required: missing or invalid user identity")
			c.Abort()
			return
		}
		c.Next()
	}
}

// RequireRole middleware ensures the caller has at least one of the specified roles.
func RequireRole(allowedRoles ...string) gin.HandlerFunc {
	allowedMap := make(map[string]bool)
	for _, r := range allowedRoles {
		allowedMap[strings.ToLower(strings.TrimSpace(r))] = true
	}
	// Admin always allowed
	allowedMap[constants.RoleAdmin] = true

	return func(c *gin.Context) {
		roles := GetUserRoles(c)
		for _, r := range roles {
			if allowedMap[r] {
				c.Next()
				return
			}
		}

		response.Forbidden(c, "Forbidden: insufficient role privileges")
		c.Abort()
	}
}
