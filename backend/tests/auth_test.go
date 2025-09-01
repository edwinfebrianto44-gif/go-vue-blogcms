package services_test

import (
	"errors"
	"testing"
	"time"

	"backend/internal/models"
	"backend/internal/services"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"gorm.io/gorm"
)

// Mock repositories
type MockUserRepository struct {
	mock.Mock
}

func (m *MockUserRepository) Create(user *models.User) error {
	args := m.Called(user)
	return args.Error(0)
}

func (m *MockUserRepository) GetByID(id uint) (*models.User, error) {
	args := m.Called(id)
	return args.Get(0).(*models.User), args.Error(1)
}

func (m *MockUserRepository) GetByUsername(username string) (*models.User, error) {
	args := m.Called(username)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.User), args.Error(1)
}

func (m *MockUserRepository) GetByEmail(email string) (*models.User, error) {
	args := m.Called(email)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.User), args.Error(1)
}

func (m *MockUserRepository) Update(user *models.User) error {
	args := m.Called(user)
	return args.Error(0)
}

func (m *MockUserRepository) Delete(id uint) error {
	args := m.Called(id)
	return args.Error(0)
}

func (m *MockUserRepository) List(page, limit int) ([]*models.User, int64, error) {
	args := m.Called(page, limit)
	return args.Get(0).([]*models.User), args.Get(1).(int64), args.Error(2)
}

type MockRefreshTokenRepository struct {
	mock.Mock
}

func (m *MockRefreshTokenRepository) Create(token *models.RefreshToken) error {
	args := m.Called(token)
	return args.Error(0)
}

func (m *MockRefreshTokenRepository) GetByToken(token string) (*models.RefreshToken, error) {
	args := m.Called(token)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.RefreshToken), args.Error(1)
}

func (m *MockRefreshTokenRepository) GetByUserID(userID uint) ([]*models.RefreshToken, error) {
	args := m.Called(userID)
	return args.Get(0).([]*models.RefreshToken), args.Error(1)
}

func (m *MockRefreshTokenRepository) RevokeToken(token string) error {
	args := m.Called(token)
	return args.Error(0)
}

func (m *MockRefreshTokenRepository) RevokeAllUserTokens(userID uint) error {
	args := m.Called(userID)
	return args.Error(0)
}

func (m *MockRefreshTokenRepository) DeleteExpiredTokens() error {
	args := m.Called()
	return args.Error(0)
}

func (m *MockRefreshTokenRepository) Update(token *models.RefreshToken) error {
	args := m.Called(token)
	return args.Error(0)
}

func (m *MockRefreshTokenRepository) Delete(id uint) error {
	args := m.Called(id)
	return args.Error(0)
}

// Mock JWT Service
type MockJWTService struct {
	mock.Mock
}

func (m *MockJWTService) GenerateTokenPair(user *models.User) (*models.AuthResponse, error) {
	args := m.Called(user)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.AuthResponse), args.Error(1)
}

func (m *MockJWTService) ValidateAccessToken(tokenString string) (*models.JWTClaims, error) {
	args := m.Called(tokenString)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.JWTClaims), args.Error(1)
}

func (m *MockJWTService) ValidateRefreshToken(tokenString string) (*models.JWTClaims, error) {
	args := m.Called(tokenString)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.JWTClaims), args.Error(1)
}

func (m *MockJWTService) RefreshAccessToken(refreshToken string) (*models.RefreshTokenResponse, error) {
	args := m.Called(refreshToken)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.RefreshTokenResponse), args.Error(1)
}

func (m *MockJWTService) RevokeRefreshToken(tokenString string) error {
	args := m.Called(tokenString)
	return args.Error(0)
}

func (m *MockJWTService) RevokeAllUserTokens(userID uint) error {
	args := m.Called(userID)
	return args.Error(0)
}

func (m *MockJWTService) HashPassword(password string) (string, error) {
	args := m.Called(password)
	return args.String(0), args.Error(1)
}

func (m *MockJWTService) CheckPassword(password, hash string) bool {
	args := m.Called(password, hash)
	return args.Bool(0)
}

// Test cases for AuthService
func TestAuthService_Login_Success(t *testing.T) {
	mockUserRepo := new(MockUserRepository)
	mockJWTService := new(MockJWTService)
	
	authService := services.NewAuthService(mockUserRepo, mockJWTService, nil)

	user := &models.User{
		ID:       1,
		Email:    "test@example.com",
		Username: "testuser",
		Password: "hashedpassword",
		Role:     "author",
	}

	authResponse := &models.AuthResponse{
		AccessToken:  "access_token",
		RefreshToken: "refresh_token",
		TokenType:    "Bearer",
		ExpiresIn:    900,
		User:         *user,
	}

	loginReq := &models.LoginRequest{
		Email:    "test@example.com",
		Password: "password123",
	}

	mockUserRepo.On("GetByEmail", "test@example.com").Return(user, nil)
	mockJWTService.On("CheckPassword", "password123", "hashedpassword").Return(true)
	mockJWTService.On("GenerateTokenPair", user).Return(authResponse, nil)

	result, err := authService.Login(loginReq)

	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.Equal(t, "access_token", result.AccessToken)
	assert.Equal(t, "refresh_token", result.RefreshToken)
	mockUserRepo.AssertExpectations(t)
	mockJWTService.AssertExpectations(t)
}

func TestAuthService_Login_InvalidPassword(t *testing.T) {
	mockUserRepo := new(MockUserRepository)
	mockJWTService := new(MockJWTService)
	
	authService := services.NewAuthService(mockUserRepo, mockJWTService, nil)

	user := &models.User{
		ID:       1,
		Email:    "test@example.com",
		Username: "testuser",
		Password: "hashedpassword",
		Role:     "author",
	}

	loginReq := &models.LoginRequest{
		Email:    "test@example.com",
		Password: "wrongpassword",
	}

	mockUserRepo.On("GetByEmail", "test@example.com").Return(user, nil)
	mockJWTService.On("CheckPassword", "wrongpassword", "hashedpassword").Return(false)

	result, err := authService.Login(loginReq)

	assert.Error(t, err)
	assert.Nil(t, result)
	assert.Contains(t, err.Error(), "invalid email or password")
	mockUserRepo.AssertExpectations(t)
	mockJWTService.AssertExpectations(t)
}

func TestAuthService_Login_UserNotFound(t *testing.T) {
	mockUserRepo := new(MockUserRepository)
	mockJWTService := new(MockJWTService)
	
	authService := services.NewAuthService(mockUserRepo, mockJWTService, nil)

	loginReq := &models.LoginRequest{
		Email:    "nonexistent@example.com",
		Password: "password123",
	}

	mockUserRepo.On("GetByEmail", "nonexistent@example.com").Return((*models.User)(nil), gorm.ErrRecordNotFound)

	result, err := authService.Login(loginReq)

	assert.Error(t, err)
	assert.Nil(t, result)
	assert.Contains(t, err.Error(), "invalid email or password")
	mockUserRepo.AssertExpectations(t)
}

func TestAuthService_RefreshToken_Success(t *testing.T) {
	mockUserRepo := new(MockUserRepository)
	mockJWTService := new(MockJWTService)
	
	authService := services.NewAuthService(mockUserRepo, mockJWTService, nil)

	refreshResponse := &models.RefreshTokenResponse{
		AccessToken:  "new_access_token",
		RefreshToken: "new_refresh_token",
		TokenType:    "Bearer",
		ExpiresIn:    900,
	}

	refreshReq := &models.RefreshTokenRequest{
		RefreshToken: "valid_refresh_token",
	}

	mockJWTService.On("RefreshAccessToken", "valid_refresh_token").Return(refreshResponse, nil)

	result, err := authService.RefreshToken(refreshReq)

	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.Equal(t, "new_access_token", result.AccessToken)
	assert.Equal(t, "new_refresh_token", result.RefreshToken)
	mockJWTService.AssertExpectations(t)
}

func TestAuthService_RefreshToken_Invalid(t *testing.T) {
	mockUserRepo := new(MockUserRepository)
	mockJWTService := new(MockJWTService)
	
	authService := services.NewAuthService(mockUserRepo, mockJWTService, nil)

	refreshReq := &models.RefreshTokenRequest{
		RefreshToken: "invalid_refresh_token",
	}

	mockJWTService.On("RefreshAccessToken", "invalid_refresh_token").Return((*models.RefreshTokenResponse)(nil), errors.New("invalid refresh token"))

	result, err := authService.RefreshToken(refreshReq)

	assert.Error(t, err)
	assert.Nil(t, result)
	assert.Contains(t, err.Error(), "invalid or expired refresh token")
	mockJWTService.AssertExpectations(t)
}

// Test JWT Service
func TestJWTService_HashPassword(t *testing.T) {
	mockRefreshTokenRepo := new(MockRefreshTokenRepository)
	jwtService := services.NewJWTService(mockRefreshTokenRepo)

	password := "testpassword123"
	
	hash, err := jwtService.HashPassword(password)
	
	assert.NoError(t, err)
	assert.NotEmpty(t, hash)
	assert.NotEqual(t, password, hash)
}

func TestJWTService_CheckPassword(t *testing.T) {
	mockRefreshTokenRepo := new(MockRefreshTokenRepository)
	jwtService := services.NewJWTService(mockRefreshTokenRepo)

	password := "testpassword123"
	hash, _ := jwtService.HashPassword(password)
	
	// Correct password
	result := jwtService.CheckPassword(password, hash)
	assert.True(t, result)
	
	// Wrong password
	result = jwtService.CheckPassword("wrongpassword", hash)
	assert.False(t, result)
}

func TestJWTService_GenerateTokenPair(t *testing.T) {
	mockRefreshTokenRepo := new(MockRefreshTokenRepository)
	jwtService := services.NewJWTService(mockRefreshTokenRepo)

	user := &models.User{
		ID:       1,
		Email:    "test@example.com",
		Username: "testuser",
		Role:     "author",
	}

	mockRefreshTokenRepo.On("Create", mock.AnythingOfType("*models.RefreshToken")).Return(nil)

	result, err := jwtService.GenerateTokenPair(user)

	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.NotEmpty(t, result.AccessToken)
	assert.NotEmpty(t, result.RefreshToken)
	assert.Equal(t, "Bearer", result.TokenType)
	assert.Greater(t, result.ExpiresIn, int64(0))
	mockRefreshTokenRepo.AssertExpectations(t)
}

func TestJWTService_ValidateAccessToken(t *testing.T) {
	mockRefreshTokenRepo := new(MockRefreshTokenRepository)
	jwtService := services.NewJWTService(mockRefreshTokenRepo)

	user := &models.User{
		ID:       1,
		Email:    "test@example.com",
		Username: "testuser",
		Role:     "author",
	}

	mockRefreshTokenRepo.On("Create", mock.AnythingOfType("*models.RefreshToken")).Return(nil)

	// Generate a valid token
	authResponse, _ := jwtService.GenerateTokenPair(user)
	
	// Validate the token
	claims, err := jwtService.ValidateAccessToken(authResponse.AccessToken)

	assert.NoError(t, err)
	assert.NotNil(t, claims)
	assert.Equal(t, user.ID, claims.UserID)
	assert.Equal(t, user.Email, claims.Email)
	assert.Equal(t, user.Username, claims.Username)
	assert.Equal(t, user.Role, claims.Role)
	assert.Equal(t, "access", claims.Type)
}

func TestJWTService_ValidateAccessToken_Invalid(t *testing.T) {
	mockRefreshTokenRepo := new(MockRefreshTokenRepository)
	jwtService := services.NewJWTService(mockRefreshTokenRepo)

	// Test with invalid token
	claims, err := jwtService.ValidateAccessToken("invalid_token")

	assert.Error(t, err)
	assert.Nil(t, claims)
}

func TestJWTService_ValidateRefreshToken_Success(t *testing.T) {
	mockRefreshTokenRepo := new(MockRefreshTokenRepository)
	jwtService := services.NewJWTService(mockRefreshTokenRepo)

	refreshToken := &models.RefreshToken{
		ID:        1,
		UserID:    1,
		Token:     "valid_token",
		ExpiresAt: time.Now().Add(24 * time.Hour),
		IsRevoked: false,
		User: &models.User{
			ID:       1,
			Email:    "test@example.com",
			Username: "testuser",
			Role:     "author",
		},
	}

	mockRefreshTokenRepo.On("GetByToken", "valid_token").Return(refreshToken, nil)

	claims, err := jwtService.ValidateRefreshToken("valid_token")

	assert.NoError(t, err)
	assert.NotNil(t, claims)
	assert.Equal(t, uint(1), claims.UserID)
	assert.Equal(t, "refresh", claims.Type)
	mockRefreshTokenRepo.AssertExpectations(t)
}

func TestJWTService_ValidateRefreshToken_Expired(t *testing.T) {
	mockRefreshTokenRepo := new(MockRefreshTokenRepository)
	jwtService := services.NewJWTService(mockRefreshTokenRepo)

	refreshToken := &models.RefreshToken{
		ID:        1,
		UserID:    1,
		Token:     "expired_token",
		ExpiresAt: time.Now().Add(-24 * time.Hour), // Expired
		IsRevoked: false,
	}

	mockRefreshTokenRepo.On("GetByToken", "expired_token").Return(refreshToken, nil)

	claims, err := jwtService.ValidateRefreshToken("expired_token")

	assert.Error(t, err)
	assert.Nil(t, claims)
	assert.Contains(t, err.Error(), "expired")
	mockRefreshTokenRepo.AssertExpectations(t)
}

func TestJWTService_ValidateRefreshToken_Revoked(t *testing.T) {
	mockRefreshTokenRepo := new(MockRefreshTokenRepository)
	jwtService := services.NewJWTService(mockRefreshTokenRepo)

	refreshToken := &models.RefreshToken{
		ID:        1,
		UserID:    1,
		Token:     "revoked_token",
		ExpiresAt: time.Now().Add(24 * time.Hour),
		IsRevoked: true, // Revoked
	}

	mockRefreshTokenRepo.On("GetByToken", "revoked_token").Return(refreshToken, nil)

	claims, err := jwtService.ValidateRefreshToken("revoked_token")

	assert.Error(t, err)
	assert.Nil(t, claims)
	assert.Contains(t, err.Error(), "revoked")
	mockRefreshTokenRepo.AssertExpectations(t)
}
