package services

import (
	"testing"

	"backend/internal/config"
	"backend/internal/models"
	"backend/internal/testutils"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
	"golang.org/x/crypto/bcrypt"
)

// MockUserRepository is a mock implementation of UserRepository
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

func (m *MockUserRepository) List(offset, limit int) ([]*models.User, error) {
	args := m.Called(offset, limit)
	return args.Get(0).([]*models.User), args.Error(1)
}

func (m *MockUserRepository) Count() (int64, error) {
	args := m.Called()
	return args.Get(0).(int64), args.Error(1)
}

// MockJWTService is a mock implementation of JWTService
type MockJWTService struct {
	mock.Mock
}

func (m *MockJWTService) GenerateTokenPair(userID uint, userRole string) (string, string, error) {
	args := m.Called(userID, userRole)
	return args.String(0), args.String(1), args.Error(2)
}

func (m *MockJWTService) ValidateAccessToken(token string) (*models.JWTClaims, error) {
	args := m.Called(token)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.JWTClaims), args.Error(1)
}

func (m *MockJWTService) ValidateRefreshToken(token string) (*models.JWTClaims, error) {
	args := m.Called(token)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.JWTClaims), args.Error(1)
}

func (m *MockJWTService) RefreshAccessToken(refreshToken string) (string, string, error) {
	args := m.Called(refreshToken)
	return args.String(0), args.String(1), args.Error(2)
}

func (m *MockJWTService) RevokeRefreshToken(refreshToken string) error {
	args := m.Called(refreshToken)
	return args.Error(0)
}

func (m *MockJWTService) RevokeAllRefreshTokens(userID uint) error {
	args := m.Called(userID)
	return args.Error(0)
}

func TestAuthService_Register(t *testing.T) {
	// Setup
	mockUserRepo := new(MockUserRepository)
	mockJWTService := new(MockJWTService)
	cfg := &config.Config{
		Environment: "test",
	}
	authService := NewAuthService(mockUserRepo, mockJWTService, cfg)

	t.Run("successful registration", func(t *testing.T) {
		// Given
		registerData := &models.RegisterRequest{
			Name:     "Test User",
			Email:    "test@example.com",
			Password: "password123",
			Role:     "author",
		}

		expectedUser := &models.User{
			ID:    1,
			Name:  "Test User",
			Email: "test@example.com",
			Role:  "author",
		}

		// Mock expectations
		mockUserRepo.On("GetByEmail", "test@example.com").Return(nil, nil).Once()
		mockUserRepo.On("Create", mock.AnythingOfType("*models.User")).Return(nil).Once()
		mockJWTService.On("GenerateTokenPair", uint(1), "author").Return("access_token", "refresh_token", nil).Once()

		// Set up the Create method to populate ID
		mockUserRepo.On("Create", mock.AnythingOfType("*models.User")).Run(func(args mock.Arguments) {
			user := args.Get(0).(*models.User)
			user.ID = 1
		}).Return(nil)

		// When
		result, err := authService.Register(registerData)

		// Then
		require.NoError(t, err)
		assert.True(t, result.Success)
		assert.Equal(t, "Registration successful", result.Message)
		assert.Equal(t, "access_token", result.AccessToken)
		assert.Equal(t, "refresh_token", result.RefreshToken)
		assert.Equal(t, expectedUser.Name, result.User.Name)
		assert.Equal(t, expectedUser.Email, result.User.Email)
		assert.Equal(t, expectedUser.Role, result.User.Role)

		mockUserRepo.AssertExpectations(t)
		mockJWTService.AssertExpectations(t)
	})

	t.Run("email already exists", func(t *testing.T) {
		// Given
		registerData := &models.RegisterRequest{
			Name:     "Test User",
			Email:    "existing@example.com",
			Password: "password123",
			Role:     "author",
		}

		existingUser := &models.User{
			ID:    1,
			Email: "existing@example.com",
		}

		// Mock expectations
		mockUserRepo.On("GetByEmail", "existing@example.com").Return(existingUser, nil).Once()

		// When
		result, err := authService.Register(registerData)

		// Then
		require.NoError(t, err)
		assert.False(t, result.Success)
		assert.Equal(t, "Email already exists", result.Message)

		mockUserRepo.AssertExpectations(t)
	})
}

func TestAuthService_Login(t *testing.T) {
	// Setup
	mockUserRepo := new(MockUserRepository)
	mockJWTService := new(MockJWTService)
	cfg := &config.Config{
		Environment: "test",
	}
	authService := NewAuthService(mockUserRepo, mockJWTService, cfg)

	t.Run("successful login", func(t *testing.T) {
		// Given
		hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("password123"), bcrypt.DefaultCost)
		user := &models.User{
			ID:       1,
			Name:     "Test User",
			Email:    "test@example.com",
			Password: string(hashedPassword),
			Role:     "author",
		}

		loginData := &models.LoginRequest{
			Email:    "test@example.com",
			Password: "password123",
		}

		// Mock expectations
		mockUserRepo.On("GetByEmail", "test@example.com").Return(user, nil).Once()
		mockJWTService.On("GenerateTokenPair", uint(1), "author").Return("access_token", "refresh_token", nil).Once()

		// When
		result, err := authService.Login(loginData)

		// Then
		require.NoError(t, err)
		assert.True(t, result.Success)
		assert.Equal(t, "Login successful", result.Message)
		assert.Equal(t, "access_token", result.AccessToken)
		assert.Equal(t, "refresh_token", result.RefreshToken)
		assert.Equal(t, user.Name, result.User.Name)

		mockUserRepo.AssertExpectations(t)
		mockJWTService.AssertExpectations(t)
	})

	t.Run("invalid email", func(t *testing.T) {
		// Given
		loginData := &models.LoginRequest{
			Email:    "invalid@example.com",
			Password: "password123",
		}

		// Mock expectations
		mockUserRepo.On("GetByEmail", "invalid@example.com").Return(nil, nil).Once()

		// When
		result, err := authService.Login(loginData)

		// Then
		require.NoError(t, err)
		assert.False(t, result.Success)
		assert.Equal(t, "Invalid credentials", result.Message)

		mockUserRepo.AssertExpectations(t)
	})

	t.Run("invalid password", func(t *testing.T) {
		// Given
		hashedPassword, _ := bcrypt.GenerateFromPassword([]byte("correctpassword"), bcrypt.DefaultCost)
		user := &models.User{
			ID:       1,
			Email:    "test@example.com",
			Password: string(hashedPassword),
		}

		loginData := &models.LoginRequest{
			Email:    "test@example.com",
			Password: "wrongpassword",
		}

		// Mock expectations
		mockUserRepo.On("GetByEmail", "test@example.com").Return(user, nil).Once()

		// When
		result, err := authService.Login(loginData)

		// Then
		require.NoError(t, err)
		assert.False(t, result.Success)
		assert.Equal(t, "Invalid credentials", result.Message)

		mockUserRepo.AssertExpectations(t)
	})
}

func TestAuthService_ChangePassword(t *testing.T) {
	// Setup
	mockUserRepo := new(MockUserRepository)
	mockJWTService := new(MockJWTService)
	cfg := &config.Config{
		Environment: "test",
	}
	authService := NewAuthService(mockUserRepo, mockJWTService, cfg)

	t.Run("successful password change", func(t *testing.T) {
		// Given
		oldHashedPassword, _ := bcrypt.GenerateFromPassword([]byte("oldpassword"), bcrypt.DefaultCost)
		user := &models.User{
			ID:       1,
			Email:    "test@example.com",
			Password: string(oldHashedPassword),
		}

		changePasswordData := &models.ChangePasswordRequest{
			CurrentPassword: "oldpassword",
			NewPassword:     "newpassword123",
		}

		// Mock expectations
		mockUserRepo.On("GetByID", uint(1)).Return(user, nil).Once()
		mockUserRepo.On("Update", mock.AnythingOfType("*models.User")).Return(nil).Once()

		// When
		result, err := authService.ChangePassword(1, changePasswordData)

		// Then
		require.NoError(t, err)
		assert.True(t, result.Success)
		assert.Equal(t, "Password changed successfully", result.Message)

		mockUserRepo.AssertExpectations(t)
	})

	t.Run("invalid current password", func(t *testing.T) {
		// Given
		oldHashedPassword, _ := bcrypt.GenerateFromPassword([]byte("correctoldpassword"), bcrypt.DefaultCost)
		user := &models.User{
			ID:       1,
			Password: string(oldHashedPassword),
		}

		changePasswordData := &models.ChangePasswordRequest{
			CurrentPassword: "wrongoldpassword",
			NewPassword:     "newpassword123",
		}

		// Mock expectations
		mockUserRepo.On("GetByID", uint(1)).Return(user, nil).Once()

		// When
		result, err := authService.ChangePassword(1, changePasswordData)

		// Then
		require.NoError(t, err)
		assert.False(t, result.Success)
		assert.Equal(t, "Current password is incorrect", result.Message)

		mockUserRepo.AssertExpectations(t)
	})
}

func TestAuthService_Integration(t *testing.T) {
	// Setup test database
	db := testutils.MockDatabase(t)

	// Create real services with test database
	userRepo := NewUserRepository(db)
	jwtService := NewJWTService(NewRefreshTokenRepository(db))
	cfg := &config.Config{
		Environment: "test",
		JWTSecret:   "test-secret",
	}
	authService := NewAuthService(userRepo, jwtService, cfg)

	t.Run("full registration and login flow", func(t *testing.T) {
		// Register a user
		registerData := &models.RegisterRequest{
			Name:     "Integration Test User",
			Email:    "integration@test.com",
			Password: "password123",
			Role:     "author",
		}

		registerResult, err := authService.Register(registerData)
		require.NoError(t, err)
		assert.True(t, registerResult.Success)
		assert.NotEmpty(t, registerResult.AccessToken)
		assert.NotEmpty(t, registerResult.RefreshToken)

		// Login with the same credentials
		loginData := &models.LoginRequest{
			Email:    "integration@test.com",
			Password: "password123",
		}

		loginResult, err := authService.Login(loginData)
		require.NoError(t, err)
		assert.True(t, loginResult.Success)
		assert.NotEmpty(t, loginResult.AccessToken)
		assert.NotEmpty(t, loginResult.RefreshToken)
		assert.Equal(t, "Integration Test User", loginResult.User.Name)
	})
}
