package dto

import (
	"errors"
	"time"

	"github.com/TranVinhHien/music-core-app/music-core-api/internal/models"
	"github.com/google/uuid"
)

type RegisterRequest struct {
	Email       string   `json:"email" binding:"required,email"`
	Password    string   `json:"password" binding:"required,min=6"`
	FullName    string   `json:"full_name" binding:"required"`
	AvatarURL   *string  `json:"avatar_url"`
	PhoneNumber *string  `json:"phone_number"`
	HomeAddress *string  `json:"home_address"`
	CurrentLat  *float64 `json:"current_lat"`
	CurrentLng  *float64 `json:"current_lng"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

type LogoutRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

type UpdateProfileRequest struct {
	FullName    *string `json:"full_name"`
	PhoneNumber *string `json:"phone_number"`
	HomeAddress *string `json:"home_address"`
	AvatarURL   *string `json:"avatar_url"`
}

type UpdatePasswordRequest struct {
	OldPassword string `json:"old_password" binding:"required"`
	NewPassword string `json:"new_password" binding:"required,min=6"`
}

type RegisterInput struct {
	Email       string
	Password    string
	FullName    string
	AvatarURL   *string
	PhoneNumber *string
	HomeAddress *string
	CurrentLat  *float64
	CurrentLng  *float64
}

type LoginInput struct {
	Email     string
	Password  string
	ClientIP  *string
	UserAgent *string
}

type RefreshTokenInput struct {
	RefreshToken string
}

type LogoutInput struct {
	RefreshToken string
}

type GetUserInput struct {
	UserID uuid.UUID
}

type UpdateProfileInput struct {
	UserID      uuid.UUID
	FullName    *string
	PhoneNumber *string
	HomeAddress *string
	AvatarURL   *string
}

type UpdatePasswordInput struct {
	UserID      uuid.UUID
	OldPassword string
	NewPassword string
}

type ValidateTokenInput struct {
	Token string
}

type TokenClaimsResponse struct {
	UserID uuid.UUID `json:"user_id"`
	Email  string    `json:"email"`
}

type UserProfileResponse struct {
	UserID           uuid.UUID  `json:"user_id"`
	FullName         *string    `json:"full_name,omitempty"`
	AvatarURL        *string    `json:"avatar_url,omitempty"`
	PhoneNumber      *string    `json:"phone_number,omitempty"`
	HomeAddress      *string    `json:"home_address,omitempty"`
	CurrentLat       *float64   `json:"current_lat,omitempty"`
	CurrentLng       *float64   `json:"current_lng,omitempty"`
	CurrentCheckinAt *time.Time `json:"current_checkin_at,omitempty"`
	UpdatedAt        time.Time  `json:"updated_at"`
}

type UserResponse struct {
	ID        uuid.UUID            `json:"id"`
	Email     string               `json:"email"`
	Provider  string               `json:"provider"`
	IsActive  bool                 `json:"is_active"`
	CreatedAt time.Time            `json:"created_at"`
	UpdatedAt time.Time            `json:"updated_at"`
	Profile   *UserProfileResponse `json:"profile,omitempty"`
}

type AuthResponse struct {
	Token        string        `json:"token"`
	RefreshToken string        `json:"refresh_token"`
	User         *UserResponse `json:"user"`
}

func NewUserResponse(user *models.UserCredential) *UserResponse {
	if user == nil {
		return nil
	}

	response := &UserResponse{
		ID:        user.ID,
		Email:     user.Email,
		Provider:  string(user.Provider),
		IsActive:  user.IsActive,
		CreatedAt: user.CreatedAt,
		UpdatedAt: user.UpdatedAt,
	}
	if user.Profile != nil {
		response.Profile = &UserProfileResponse{
			UserID:           user.Profile.UserID,
			FullName:         user.Profile.FullName,
			AvatarURL:        user.Profile.AvatarURL,
			PhoneNumber:      user.Profile.PhoneNumber,
			HomeAddress:      user.Profile.HomeAddress,
			CurrentLat:       user.Profile.CurrentLat,
			CurrentLng:       user.Profile.CurrentLng,
			CurrentCheckinAt: user.Profile.CurrentCheckinAt,
			UpdatedAt:        user.Profile.UpdatedAt,
		}
	}

	return response
}

var (
	ErrEmailExists        = errors.New("email already exists")
	ErrInvalidCredentials = errors.New("invalid email or password")
	ErrUserNotFound       = errors.New("user not found")
	ErrUserInactive       = errors.New("user account is inactive")
	ErrInvalidToken       = errors.New("invalid or expired token")
)
