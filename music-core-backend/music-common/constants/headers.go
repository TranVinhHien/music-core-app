package constants

// Standard HTTP Header names used across microservices.
const (
	HeaderRequestID     = "X-Request-ID"
	HeaderUserID        = "X-User-ID"
	HeaderUserEmail     = "X-User-Email"
	HeaderUserRoles     = "X-User-Roles"
	HeaderAuthorization = "Authorization"
	HeaderContentType   = "Content-Type"
)

// Gin and Context key names.
const (
	CtxKeyRequestID = "request_id"
	CtxKeyUserID    = "user_id"
	CtxKeyUserEmail = "user_email"
	CtxKeyEmail     = "email"
	CtxKeyUserRoles = "user_roles"
)

// Common role names.
const (
	RoleAdmin = "admin"
	RoleUser  = "user"
)

// Auth header prefixes.
const (
	BearerPrefix = "Bearer"
)
