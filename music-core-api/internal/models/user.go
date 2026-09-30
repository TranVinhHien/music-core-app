package models

import (
	"time"

	"github.com/google/uuid"
)

// AuthProvider defines supported authentication providers.
type AuthProvider string

const (
	AuthProviderLocal  AuthProvider = "local"
	AuthProviderGoogle AuthProvider = "google"
	AuthProviderApple  AuthProvider = "apple"
)

// UserCredential stores core authentication information.
type UserCredential struct {
	ID           uuid.UUID    `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	Email        string       `gorm:"type:varchar(255);uniqueIndex;not null" json:"email"`
	PasswordHash string       `gorm:"type:varchar(255);not null" json:"-"` // Hidden from JSON responses for security.
	Provider     AuthProvider `gorm:"type:varchar(50);default:'local'" json:"provider"`
	ProviderID   *string      `gorm:"type:varchar(255)" json:"provider_id,omitempty"`
	IsActive     bool         `gorm:"type:boolean;default:true" json:"is_active"`
	CreatedAt    time.Time    `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt    time.Time    `gorm:"autoUpdateTime" json:"updated_at"`

	// Relationships
	Profile       *UserProfile   `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE;" json:"profile,omitempty"`
	RefreshTokens []RefreshToken `gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE;" json:"refresh_tokens,omitempty"`
}

func (UserCredential) TableName() string {
	return "user_credentials"
}

// UserProfile stores display and personal information for a user.
type UserProfile struct {
	UserID      uuid.UUID `gorm:"type:uuid;primaryKey" json:"user_id"`
	FullName    *string   `gorm:"type:varchar(255)" json:"full_name,omitempty"`
	AvatarURL   *string   `gorm:"type:varchar(500)" json:"avatar_url,omitempty"`
	PhoneNumber *string   `gorm:"type:varchar(20)" json:"phone_number,omitempty"`
	HomeAddress *string   `gorm:"type:text" json:"home_address,omitempty"`

	CurrentLat       *float64   `gorm:"type:double precision" json:"current_lat,omitempty"`
	CurrentLng       *float64   `gorm:"type:double precision" json:"current_lng,omitempty"`
	CurrentCheckinAt *time.Time `gorm:"type:timestamp" json:"current_checkin_at,omitempty"`

	UpdatedAt time.Time `gorm:"autoUpdateTime" json:"updated_at"`
}

func (UserProfile) TableName() string {
	return "user_profiles"
}

// RefreshToken stores a token used to issue a new access token.
type RefreshToken struct {
	ID     uuid.UUID `gorm:"type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	UserID uuid.UUID `gorm:"type:uuid;not null;index:idx_refresh_tokens_user_id" json:"user_id"`

	Token     string    `gorm:"type:text;uniqueIndex:idx_refresh_tokens_token;not null" json:"token"`
	ExpiresAt time.Time `gorm:"type:timestamp;not null" json:"expires_at"`
	IsRevoked bool      `gorm:"type:boolean;default:false" json:"is_revoked"`

	ClientIP  *string `gorm:"type:varchar(45)" json:"client_ip,omitempty"`
	UserAgent *string `gorm:"type:text" json:"user_agent,omitempty"`

	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time `gorm:"autoUpdateTime" json:"updated_at"`
}

func (RefreshToken) TableName() string {
	return "refresh_tokens"
}
