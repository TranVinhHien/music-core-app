package services

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"github.com/TranVinhHien/music-core-app/music-core-api/internal/config"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/handlers/dto"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/logging"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/models"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/repository"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type AuthService struct {
	userRepo repository.IUserRepository
}

func NewAuthService(userRepo repository.IUserRepository) *AuthService {
	return &AuthService{userRepo: userRepo}
}

func (s *AuthService) Register(ctx context.Context, input dto.RegisterInput) (*dto.UserResponse, error) {
	var err error
	defer func() {
		if err != nil {
			logging.Error(ctx, "AuthService.Register", err)
		}
	}()

	// Check if user already exists
	existingUser, _ := s.userRepo.FindByEmail(ctx, input.Email)
	if existingUser != nil {
		err = dto.ErrEmailExists
		return nil, err
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("hash password: %w", err)
	}

	// Create user
	user := &models.UserCredential{
		Email:        input.Email,
		PasswordHash: string(hashedPassword),
		IsActive:     true,
		Provider:     models.AuthProviderLocal,
	}

	if err = s.userRepo.Create(ctx, user); err != nil {
		return nil, fmt.Errorf("create user: %w", err)
	}

	// Create initial profile
	profile := &models.UserProfile{
		UserID:      user.ID,
		FullName:    &input.FullName,
		AvatarURL:   input.AvatarURL,
		PhoneNumber: input.PhoneNumber,
		HomeAddress: input.HomeAddress,
		CurrentLat:  input.CurrentLat,
		CurrentLng:  input.CurrentLng,
	}
	_ = s.userRepo.UpdateProfile(ctx, profile) // ignoring error for simple profile creation

	user.Profile = profile
	return dto.NewUserResponse(user), nil
}

func (s *AuthService) Login(ctx context.Context, input dto.LoginInput) (resp *dto.AuthResponse, err error) {
	defer func() {
		if err != nil {
			logging.Error(ctx, "AuthService.Login", err)
		}
	}()
	// Find user
	user, err := s.userRepo.FindByEmail(ctx, input.Email)
	if err != nil {

		err = dto.ErrUserNotFound
		return nil, err
	}

	// Check status
	if !user.IsActive {
		err = dto.ErrUserInactive
		return nil, err
	}

	// Compare password
	if err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(input.Password)); err != nil {
		err = dto.ErrInvalidCredentials
		return nil, err
	}

	// Generate access token
	token, err := s.generateToken(user)
	if err != nil {
		return nil, fmt.Errorf("generate token: %w", err)
	}

	// Generate refresh token
	refreshTokenStr, err := s.generateSecureToken(32)
	if err != nil {
		return nil, fmt.Errorf("generate refresh token: %w", err)
	}

	refreshTokenExpiry := 7 * 24 * time.Hour
	if config.App.Token.RefreshTokenExpirationTime > 0 {
		refreshTokenExpiry = time.Duration(config.App.Token.RefreshTokenExpirationTime) * time.Second
	}

	refreshToken := &models.RefreshToken{
		UserID:    user.ID,
		Token:     refreshTokenStr,
		ExpiresAt: time.Now().Add(refreshTokenExpiry),
		ClientIP:  input.ClientIP,
		UserAgent: input.UserAgent,
	}

	if err = s.userRepo.CreateRefreshToken(ctx, refreshToken); err != nil {
		return nil, fmt.Errorf("save refresh token: %w", err)
	}

	return &dto.AuthResponse{
		Token:        token,
		RefreshToken: refreshTokenStr,
		User:         dto.NewUserResponse(user),
	}, nil
}

func (s *AuthService) RefreshToken(ctx context.Context, input dto.RefreshTokenInput) (*dto.AuthResponse, error) {
	var err error
	defer func() {
		if err != nil {
			logging.Error(ctx, "AuthService.RefreshToken", err)
		}
	}()

	rt, err := s.userRepo.FindRefreshToken(ctx, input.RefreshToken)
	if err != nil || rt.IsRevoked || rt.ExpiresAt.Before(time.Now()) {
		err = dto.ErrInvalidToken
		return nil, err
	}

	user, err := s.userRepo.FindByID(ctx, rt.UserID)
	if err != nil {
		err = dto.ErrInvalidToken
		return nil, err
	}

	if !user.IsActive {
		err = dto.ErrUserInactive
		return nil, err
	}

	// Generate new access token
	token, err := s.generateToken(user)
	if err != nil {
		return nil, fmt.Errorf("generate token: %w", err)
	}
	return &dto.AuthResponse{
		Token:        token,
		RefreshToken: rt.Token,
		User:         dto.NewUserResponse(user),
	}, nil
}

func (s *AuthService) Logout(ctx context.Context, input dto.LogoutInput) error {
	var err error
	defer func() {
		if err != nil {
			logging.Error(ctx, "AuthService.Logout", err)
		}
	}()

	rt, err := s.userRepo.FindRefreshToken(ctx, input.RefreshToken)
	if err != nil {
		return nil // If token not found, consider it already logged out
	}

	return s.userRepo.RevokeRefreshToken(ctx, rt.ID)
}

type JWTClaims struct {
	UserID uuid.UUID `json:"user_id"`
	Email  string    `json:"email"`
	jwt.RegisteredClaims
}

func (s *AuthService) generateToken(user *models.UserCredential) (tok string, err error) {
	ctx := context.Background()
	defer func() {
		if err != nil {
			logging.Error(ctx, "AuthService.generateToken", err)
		}
	}()

	accessTokenExpiry := 15 * time.Minute
	if config.App.Token.AccessTokenExpirationTime > 0 {
		accessTokenExpiry = time.Duration(config.App.Token.AccessTokenExpirationTime) * time.Second
	}

	claims := JWTClaims{
		UserID: user.ID,
		Email:  user.Email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(accessTokenExpiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tok, err = token.SignedString([]byte(config.App.Token.Secret))
	return tok, err
}

func (s *AuthService) ValidateToken(input dto.ValidateTokenInput) (*dto.TokenClaimsResponse, error) {
	ctx := context.Background()
	var err error
	defer func() {
		if err != nil {
			logging.Error(ctx, "AuthService.ValidateToken", err)
		}
	}()

	token, err := jwt.ParseWithClaims(input.Token, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(config.App.Token.Secret), nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*JWTClaims); ok && token.Valid {
		return &dto.TokenClaimsResponse{UserID: claims.UserID, Email: claims.Email}, nil
	}

	return nil, dto.ErrInvalidToken
}

func (s *AuthService) GetUserByID(ctx context.Context, input dto.GetUserInput) (*dto.UserResponse, error) {
	var err error
	defer func() {
		if err != nil {
			logging.Error(ctx, "AuthService.GetUserByID", err)
		}
	}()
	u, err := s.userRepo.FindByID(ctx, input.UserID)
	if err != nil {
		return nil, err
	}
	return dto.NewUserResponse(u), nil
}

func (s *AuthService) UpdateUser(ctx context.Context, input dto.UpdateProfileInput) (*dto.UserResponse, error) {
	var err error
	defer func() {
		if err != nil {
			logging.Error(ctx, "AuthService.UpdateUser", err)
		}
	}()

	user, err := s.userRepo.FindByID(ctx, input.UserID)
	if err != nil {
		return nil, err
	}

	if user.Profile == nil {
		user.Profile = &models.UserProfile{UserID: input.UserID}
	}

	if input.FullName != nil {
		user.Profile.FullName = input.FullName
	}
	if input.PhoneNumber != nil {
		user.Profile.PhoneNumber = input.PhoneNumber
	}
	if input.HomeAddress != nil {
		user.Profile.HomeAddress = input.HomeAddress
	}
	if input.AvatarURL != nil {
		user.Profile.AvatarURL = input.AvatarURL
	}

	if err = s.userRepo.UpdateProfile(ctx, user.Profile); err != nil {
		return nil, fmt.Errorf("update profile: %w", err)
	}

	return dto.NewUserResponse(user), nil
}

func (s *AuthService) UpdatePassword(ctx context.Context, input dto.UpdatePasswordInput) error {
	var err error
	defer func() {
		if err != nil {
			logging.Error(ctx, "AuthService.UpdatePassword", err)
		}
	}()

	user, err := s.userRepo.FindByID(ctx, input.UserID)
	if err != nil {
		return err
	}

	if err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(input.OldPassword)); err != nil {
		err = errors.New("invalid old password")
		return err
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(input.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("hash password: %w", err)
	}

	user.PasswordHash = string(hashedPassword)
	if err = s.userRepo.Update(ctx, user); err != nil {
		return fmt.Errorf("update user: %w", err)
	}

	// Revoke all refresh tokens on password change
	_ = s.userRepo.RevokeAllUserRefreshTokens(ctx, input.UserID)

	return nil
}

func (s *AuthService) generateSecureToken(length int) (string, error) {
	b := make([]byte, length)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}
