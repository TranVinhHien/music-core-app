package services

import (
	"context"
	"testing"
	"time"

	"github.com/TranVinhHien/music-core-app/music-core-api/internal/config"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/handlers/dto"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/models"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type fakeUserRepo struct {
	users   map[string]*models.UserCredential
	tokens  map[string]*models.RefreshToken
	updated *models.UserCredential
	profile *models.UserProfile
	revoked uuid.UUID
}

func newFakeRepo() *fakeUserRepo {
	return &fakeUserRepo{users: map[string]*models.UserCredential{}, tokens: map[string]*models.RefreshToken{}}
}
func (r *fakeUserRepo) Create(_ context.Context, u *models.UserCredential) error {
	if u.ID == uuid.Nil {
		u.ID = uuid.New()
	}
	r.users[u.Email] = u
	return nil
}
func (r *fakeUserRepo) FindByEmail(_ context.Context, e string) (*models.UserCredential, error) {
	u, ok := r.users[e]
	if !ok {
		return nil, dto.ErrUserNotFound
	}
	return u, nil
}
func (r *fakeUserRepo) FindByID(_ context.Context, id uuid.UUID) (*models.UserCredential, error) {
	for _, u := range r.users {
		if u.ID == id {
			return u, nil
		}
	}
	return nil, dto.ErrUserNotFound
}
func (r *fakeUserRepo) Update(_ context.Context, u *models.UserCredential) error {
	r.updated = u
	r.users[u.Email] = u
	return nil
}
func (r *fakeUserRepo) UpdateProfile(_ context.Context, p *models.UserProfile) error {
	r.profile = p
	return nil
}
func (r *fakeUserRepo) CreateRefreshToken(_ context.Context, t *models.RefreshToken) error {
	if t.ID == uuid.Nil {
		t.ID = uuid.New()
	}
	r.tokens[t.Token] = t
	return nil
}
func (r *fakeUserRepo) FindRefreshToken(_ context.Context, t string) (*models.RefreshToken, error) {
	v, ok := r.tokens[t]
	if !ok {
		return nil, dto.ErrInvalidToken
	}
	return v, nil
}
func (r *fakeUserRepo) RevokeRefreshToken(_ context.Context, id uuid.UUID) error {
	r.revoked = id
	return nil
}
func (r *fakeUserRepo) RevokeAllUserRefreshTokens(context.Context, uuid.UUID) error { return nil }

func TestAuthServiceRegisterLoginAndValidate(t *testing.T) {
	config.App.Token.Secret = "test-secret"
	config.App.Token.AccessTokenExpirationTime = 3600
	repo := newFakeRepo()
	s := NewAuthService(repo)
	ctx := context.Background()
	got, err := s.Register(ctx, dto.RegisterInput{Email: "a@example.com", Password: "secret123", FullName: "Alice"})
	if err != nil {
		t.Fatal(err)
	}
	if got.Email != "a@example.com" || repo.profile == nil {
		t.Fatalf("unexpected registration: %+v", got)
	}
	if _, err = s.Register(ctx, dto.RegisterInput{Email: "a@example.com", Password: "secret123", FullName: "Alice"}); err != dto.ErrEmailExists {
		t.Fatalf("duplicate error=%v", err)
	}
	auth, err := s.Login(ctx, dto.LoginInput{Email: "a@example.com", Password: "secret123"})
	if err != nil {
		t.Fatal(err)
	}
	if auth.Token == "" || auth.RefreshToken == "" {
		t.Fatal("tokens not generated")
	}
	claims, err := s.ValidateToken(dto.ValidateTokenInput{Token: auth.Token})
	if err != nil || claims.UserID != got.ID {
		t.Fatalf("claims=%+v err=%v", claims, err)
	}
	if err := s.Logout(ctx, dto.LogoutInput{RefreshToken: auth.RefreshToken}); err != nil || repo.revoked == uuid.Nil {
		t.Fatalf("logout err=%v", err)
	}
}

func TestAuthServiceErrorsAndPasswordUpdate(t *testing.T) {
	config.App.Token.Secret = "test-secret"
	repo := newFakeRepo()
	id := uuid.New()
	hash, _ := bcrypt.GenerateFromPassword([]byte("oldpass"), bcrypt.DefaultCost)
	repo.users["inactive@example.com"] = &models.UserCredential{ID: id, Email: "inactive@example.com", PasswordHash: string(hash), IsActive: false}
	s := NewAuthService(repo)
	if _, err := s.Login(context.Background(), dto.LoginInput{Email: "missing@example.com", Password: "x"}); err != dto.ErrUserNotFound {
		t.Fatal(err)
	}
	if _, err := s.Login(context.Background(), dto.LoginInput{Email: "inactive@example.com", Password: "oldpass"}); err != dto.ErrUserInactive {
		t.Fatal(err)
	}
	repo.users["active@example.com"] = &models.UserCredential{ID: uuid.New(), Email: "active@example.com", PasswordHash: string(hash), IsActive: true}
	if err := s.UpdatePassword(context.Background(), dto.UpdatePasswordInput{UserID: repo.users["active@example.com"].ID, OldPassword: "bad", NewPassword: "newpass"}); err == nil {
		t.Fatal("expected invalid old password")
	}
	if err := s.UpdatePassword(context.Background(), dto.UpdatePasswordInput{UserID: repo.users["active@example.com"].ID, OldPassword: "oldpass", NewPassword: "newpass"}); err != nil {
		t.Fatal(err)
	}
	if bcrypt.CompareHashAndPassword([]byte(repo.updated.PasswordHash), []byte("newpass")) != nil {
		t.Fatal("password not updated")
	}
	repo.tokens["expired"] = &models.RefreshToken{Token: "expired", ExpiresAt: time.Now().Add(-time.Hour)}
	if _, err := s.RefreshToken(context.Background(), dto.RefreshTokenInput{RefreshToken: "expired"}); err != dto.ErrInvalidToken {
		t.Fatal(err)
	}
}
