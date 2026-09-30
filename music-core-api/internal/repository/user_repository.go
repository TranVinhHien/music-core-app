package repository

import (
	"context"

	"github.com/TranVinhHien/music-core-app/music-core-api/internal/handlers/dto"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type IUserRepository interface {
	Create(ctx context.Context, user *models.UserCredential) error
	FindByEmail(ctx context.Context, email string) (*models.UserCredential, error)
	FindByID(ctx context.Context, id uuid.UUID) (*models.UserCredential, error)
	Update(ctx context.Context, user *models.UserCredential) error
	UpdateProfile(ctx context.Context, profile *models.UserProfile) error

	CreateRefreshToken(ctx context.Context, token *models.RefreshToken) error
	FindRefreshToken(ctx context.Context, tokenStr string) (*models.RefreshToken, error)
	RevokeRefreshToken(ctx context.Context, tokenID uuid.UUID) error
	RevokeAllUserRefreshTokens(ctx context.Context, userID uuid.UUID) error
}

type UserRepository struct {
	db *gorm.DB
}

func NewUserRepository(db *gorm.DB) IUserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) Create(ctx context.Context, user *models.UserCredential) error {
	return r.db.WithContext(ctx).Create(user).Error
}

func (r *UserRepository) FindByEmail(ctx context.Context, email string) (*models.UserCredential, error) {
	var user models.UserCredential
	if err := r.db.WithContext(ctx).Where("email = ?", email).Preload("Profile").First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, dto.ErrUserNotFound
		}
		return nil, err
	}
	return &user, nil
}

func (r *UserRepository) FindByID(ctx context.Context, id uuid.UUID) (*models.UserCredential, error) {
	var user models.UserCredential
	if err := r.db.WithContext(ctx).Where("id = ?", id).Preload("Profile").First(&user).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *UserRepository) Update(ctx context.Context, user *models.UserCredential) error {
	return r.db.WithContext(ctx).Save(user).Error
}

func (r *UserRepository) UpdateProfile(ctx context.Context, profile *models.UserProfile) error {
	return r.db.WithContext(ctx).Save(profile).Error
}

func (r *UserRepository) CreateRefreshToken(ctx context.Context, token *models.RefreshToken) error {
	return r.db.WithContext(ctx).Create(token).Error
}

func (r *UserRepository) FindRefreshToken(ctx context.Context, tokenStr string) (*models.RefreshToken, error) {
	var token models.RefreshToken
	if err := r.db.WithContext(ctx).Where("token = ?", tokenStr).First(&token).Error; err != nil {
		return nil, err
	}
	return &token, nil
}

func (r *UserRepository) RevokeRefreshToken(ctx context.Context, tokenID uuid.UUID) error {
	return r.db.WithContext(ctx).Model(&models.RefreshToken{}).Where("id = ?", tokenID).Update("is_revoked", true).Error
}

func (r *UserRepository) RevokeAllUserRefreshTokens(ctx context.Context, userID uuid.UUID) error {
	return r.db.WithContext(ctx).Model(&models.RefreshToken{}).Where("user_id = ?", userID).Update("is_revoked", true).Error
}
