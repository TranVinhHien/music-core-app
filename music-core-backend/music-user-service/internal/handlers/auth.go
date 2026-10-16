package handlers

import (
	"errors"
	"net/http"
	"strings"

	"github.com/TranVinhHien/music-core-app/music-core-backend/music-common/middleware"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-core-user/internal/handlers/dto"
	"github.com/TranVinhHien/music-core-app/music-core-backend/music-core-user/internal/services"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type AuthHandler struct {
	authService *services.AuthService
}

func NewAuthHandler(authService *services.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req dto.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, err)
		return
	}

	user, err := h.authService.Register(c.Request.Context(), dto.RegisterInput{
		Email: req.Email, Password: req.Password, FullName: req.FullName,
		AvatarURL: req.AvatarURL, PhoneNumber: req.PhoneNumber, HomeAddress: req.HomeAddress,
		CurrentLat: req.CurrentLat, CurrentLng: req.CurrentLng,
	})
	if err != nil {
		status := http.StatusInternalServerError
		if errors.Is(err, dto.ErrEmailExists) {
			status = http.StatusConflict
		}
		respondError(c, status, err)
		return
	}
	respond(c, http.StatusCreated, "user registered", user)
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req dto.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, err)
		return
	}
	clientIP, userAgent := c.ClientIP(), c.Request.UserAgent()
	response, err := h.authService.Login(c.Request.Context(), dto.LoginInput{
		Email: req.Email, Password: req.Password, ClientIP: &clientIP, UserAgent: &userAgent,
	})
	if err != nil {
		status := http.StatusInternalServerError
		if errors.Is(err, dto.ErrInvalidCredentials) {
			status = http.StatusUnauthorized
		}
		if errors.Is(err, dto.ErrUserInactive) {
			status = http.StatusForbidden
		}
		respondError(c, status, err)
		return
	}
	respond(c, http.StatusOK, "login successful", response)
}

func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req dto.RefreshTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, err)
		return
	}
	response, err := h.authService.RefreshToken(c.Request.Context(), dto.RefreshTokenInput{RefreshToken: req.RefreshToken})
	if err != nil {
		status := http.StatusInternalServerError
		if errors.Is(err, dto.ErrInvalidToken) {
			status = http.StatusUnauthorized
		}
		if errors.Is(err, dto.ErrUserInactive) {
			status = http.StatusForbidden
		}
		respondError(c, status, err)
		return
	}
	respond(c, http.StatusOK, "token refreshed", response)
}

func (h *AuthHandler) Logout(c *gin.Context) {
	var req dto.LogoutRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, err)
		return
	}
	if err := h.authService.Logout(c.Request.Context(), dto.LogoutInput{RefreshToken: req.RefreshToken}); err != nil {
		respondError(c, http.StatusInternalServerError, err)
		return
	}
	respond(c, http.StatusOK, "logged out successfully", nil)
}

func (h *AuthHandler) GetMe(c *gin.Context) {
	userID, ok := requestUserID(c)
	if !ok {
		return
	}
	user, err := h.authService.GetUserByID(c.Request.Context(), dto.GetUserInput{UserID: userID})
	if err != nil {
		respondError(c, http.StatusNotFound, dto.ErrUserNotFound)
		return
	}
	respond(c, http.StatusOK, "user retrieved", user)
}

func (h *AuthHandler) UpdateMe(c *gin.Context) {
	userID, ok := requestUserID(c)
	if !ok {
		return
	}
	var req dto.UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, err)
		return
	}
	user, err := h.authService.UpdateUser(c.Request.Context(), dto.UpdateProfileInput{
		UserID: userID, FullName: req.FullName, PhoneNumber: req.PhoneNumber,
		HomeAddress: req.HomeAddress, AvatarURL: req.AvatarURL,
	})
	if err != nil {
		respondError(c, http.StatusInternalServerError, err)
		return
	}
	respond(c, http.StatusOK, "user updated", user)
}

func (h *AuthHandler) UpdatePassword(c *gin.Context) {
	userID, ok := requestUserID(c)
	if !ok {
		return
	}
	var req dto.UpdatePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		respondError(c, http.StatusBadRequest, err)
		return
	}
	err := h.authService.UpdatePassword(c.Request.Context(), dto.UpdatePasswordInput{
		UserID: userID, OldPassword: req.OldPassword, NewPassword: req.NewPassword,
	})
	if err != nil {
		status := http.StatusInternalServerError
		if err.Error() == "invalid old password" {
			status = http.StatusBadRequest
		}
		respondError(c, status, err)
		return
	}
	respond(c, http.StatusOK, "password updated successfully", nil)
}

func requestUserID(c *gin.Context) (uuid.UUID, bool) {
	userID, ok := middleware.GetUserID(c)
	if !ok {
		respondError(c, http.StatusUnauthorized, errors.New("unauthorized"))
		return uuid.Nil, false
	}
	return userID, true
}

// AuthMiddleware extracts authentication context.
// In the microservice architecture, API Gateway handles token verification and permission checks,
// injecting X-User-ID, X-User-Email, and X-User-Roles headers.
// If X-User-ID is present, this middleware trusts the Gateway headers.
func AuthMiddleware(authService *services.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. Check Gateway injected headers first
		if gatewayUserID := c.GetHeader("X-User-ID"); gatewayUserID != "" {
			c.Set("user_id", gatewayUserID)
			if email := c.GetHeader("X-User-Email"); email != "" {
				c.Set("email", email)
			}
			if roles := c.GetHeader("X-User-Roles"); roles != "" {
				c.Set("roles", roles)
			}
			c.Next()
			return
		}

		// 2. Fallback to direct Bearer token validation if called directly
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			respondError(c, http.StatusUnauthorized, errors.New("authorization header or gateway context required"))
			c.Abort()
			return
		}
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			respondError(c, http.StatusUnauthorized, errors.New("invalid authorization header format"))
			c.Abort()
			return
		}
		if authService == nil {
			respondError(c, http.StatusUnauthorized, errors.New("authentication service unavailable"))
			c.Abort()
			return
		}
		claims, err := authService.ValidateToken(dto.ValidateTokenInput{Token: parts[1]})
		if err != nil {
			respondError(c, http.StatusUnauthorized, errors.New("invalid or expired token"))
			c.Abort()
			return
		}
		c.Set("user_id", claims.UserID.String())
		c.Set("email", claims.Email)
		c.Next()
	}
}
