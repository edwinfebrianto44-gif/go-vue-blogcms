package services

import (
	"testing"

	"backend/internal/config"
	"backend/internal/models"
	"backend/internal/repositories"
	"backend/internal/testutils"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
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
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
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

func (m *MockUserRepository) List(page, perPage int) ([]models.User, int64, error) {
	args := m.Called(page, perPage)
	return args.Get(0).([]models.User), args.Get(1).(int64), args.Error(2)
}

// MockJWTService is a mock implementation of JWTService
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

func (m *MockJWTService) RefreshAccessToken(refreshToken string) (*models.RefreshTokenResponse, error) {
	args := m.Called(refreshToken)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.RefreshTokenResponse), args.Error(1)
}

func (m *MockJWTService) RevokeRefreshToken(refreshToken string) error {
	args := m.Called(refreshToken)
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

func TestAuthService_Register(t *testing.T) {
	// Setup
	mockUserRepo := new(MockUserRepository)
	mockJWTService := new(MockJWTService)
	cfg := &config.Config{}
	authService := NewAuthService(mockUserRepo, mockJWTService, cfg)

	t.Run("successful registration", func(t *testing.T) {
		// Given
		registerData := &models.RegisterRequest{
			Username: "testuser",
			Name:     "Test User",
			Email:    "test@example.com",
			Password: "password123",
			Role:     "author",
		}

		hashedPassword := "$2a$12$hashed_password"

		// Mock expectations
		mockUserRepo.On("GetByUsername", "testuser").Return(nil, gorm.ErrRecordNotFound).Once()
		mockUserRepo.On("GetByEmail", "test@example.com").Return(nil, gorm.ErrRecordNotFound).Once()
		mockJWTService.On("HashPassword", "password123").Return(hashedPassword, nil).Once()
		mockUserRepo.On("Create", mock.AnythingOfType("*models.User")).Run(func(args mock.Arguments) {
			user := args.Get(0).(*models.User)
			user.ID = 1 // Simulate database assigning ID
		}).Return(nil).Once()

		// When
		result, err := authService.Register(registerData)

		// Then
		require.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, uint(1), result.ID)
		assert.Equal(t, "Test User", result.Name)
		assert.Equal(t, "test@example.com", result.Email)
		assert.Equal(t, "author", result.Role)

		mockUserRepo.AssertExpectations(t)
		mockJWTService.AssertExpectations(t)
	})

	t.Run("username already exists", func(t *testing.T) {
		// Given
		registerData := &models.RegisterRequest{
			Username: "existinguser",
			Email:    "test@example.com",
			Password: "password123",
		}

		existingUser := &models.User{
			ID:       1,
			Username: "existinguser",
		}

		// Mock expectations
		mockUserRepo.On("GetByUsername", "existinguser").Return(existingUser, nil).Once()

		// When
		result, err := authService.Register(registerData)

		// Then
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.Equal(t, "username already exists", err.Error())

		mockUserRepo.AssertExpectations(t)
	})

	t.Run("email already exists", func(t *testing.T) {
		// Given
		registerData := &models.RegisterRequest{
			Username: "newuser",
			Email:    "existing@example.com",
			Password: "password123",
		}

		existingUser := &models.User{
			ID:    1,
			Email: "existing@example.com",
		}

		// Mock expectations
		mockUserRepo.On("GetByUsername", "newuser").Return(nil, gorm.ErrRecordNotFound).Once()
		mockUserRepo.On("GetByEmail", "existing@example.com").Return(existingUser, nil).Once()

		// When
		result, err := authService.Register(registerData)

		// Then
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.Equal(t, "email already exists", err.Error())

		mockUserRepo.AssertExpectations(t)
	})
}

func TestAuthService_Login(t *testing.T) {
	// Setup
	mockUserRepo := new(MockUserRepository)
	mockJWTService := new(MockJWTService)
	cfg := &config.Config{}
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

		expectedAuthResponse := &models.AuthResponse{
			AccessToken:  "access_token",
			RefreshToken: "refresh_token",
			TokenType:    "Bearer",
			ExpiresIn:    3600,
			User:         *user,
		}

		// Mock expectations
		mockUserRepo.On("GetByEmail", "test@example.com").Return(user, nil).Once()
		mockJWTService.On("CheckPassword", "password123", string(hashedPassword)).Return(true).Once()
		mockJWTService.On("GenerateTokenPair", user).Return(expectedAuthResponse, nil).Once()

		// When
		result, err := authService.Login(loginData)

		// Then
		require.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, "access_token", result.AccessToken)
		assert.Equal(t, "refresh_token", result.RefreshToken)
		assert.Equal(t, "Test User", result.User.Name)

		mockUserRepo.AssertExpectations(t)
		mockJWTService.AssertExpectations(t)
	})

	t.Run("user not found", func(t *testing.T) {
		// Given
		loginData := &models.LoginRequest{
			Email:    "notfound@example.com",
			Password: "password123",
		}

		// Mock expectations
		mockUserRepo.On("GetByEmail", "notfound@example.com").Return(nil, gorm.ErrRecordNotFound).Once()

		// When
		result, err := authService.Login(loginData)

		// Then
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.Equal(t, "invalid credentials", err.Error())

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
		mockJWTService.On("CheckPassword", "wrongpassword", string(hashedPassword)).Return(false).Once()

		// When
		result, err := authService.Login(loginData)

		// Then
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.Equal(t, "invalid credentials", err.Error())

		mockUserRepo.AssertExpectations(t)
		mockJWTService.AssertExpectations(t)
	})
}

func TestAuthService_ChangePassword(t *testing.T) {
	// Setup
	mockUserRepo := new(MockUserRepository)
	mockJWTService := new(MockJWTService)
	cfg := &config.Config{}
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

		newHashedPassword := "$2a$12$new_hashed_password"

		// Mock expectations
		mockUserRepo.On("GetByID", uint(1)).Return(user, nil).Once()
		mockJWTService.On("CheckPassword", "oldpassword", string(oldHashedPassword)).Return(true).Once()
		mockJWTService.On("HashPassword", "newpassword123").Return(newHashedPassword, nil).Once()
		mockUserRepo.On("Update", mock.AnythingOfType("*models.User")).Return(nil).Once()

		// When
		err := authService.ChangePassword(1, changePasswordData)

		// Then
		require.NoError(t, err)

		mockUserRepo.AssertExpectations(t)
		mockJWTService.AssertExpectations(t)
	})

	t.Run("user not found", func(t *testing.T) {
		// Given
		changePasswordData := &models.ChangePasswordRequest{
			CurrentPassword: "oldpassword",
			NewPassword:     "newpassword123",
		}

		// Mock expectations
		mockUserRepo.On("GetByID", uint(999)).Return(nil, gorm.ErrRecordNotFound).Once()

		// When
		err := authService.ChangePassword(999, changePasswordData)

		// Then
		assert.Error(t, err)
		assert.Equal(t, "user not found", err.Error())

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
		mockJWTService.On("CheckPassword", "wrongoldpassword", string(oldHashedPassword)).Return(false).Once()

		// When
		err := authService.ChangePassword(1, changePasswordData)

		// Then
		assert.Error(t, err)
		assert.Equal(t, "invalid current password", err.Error())

		mockUserRepo.AssertExpectations(t)
		mockJWTService.AssertExpectations(t)
	})
}

func TestAuthService_Integration(t *testing.T) {
	// Setup test database
	db := testutils.MockDatabase(t)

	// Create real repositories
	userRepo := repositories.NewUserRepository(db)
	refreshTokenRepo := repositories.NewRefreshTokenRepository(db)

	// Create real services
	jwtService := NewJWTService(refreshTokenRepo)
	cfg := &config.Config{}
	authService := NewAuthService(userRepo, jwtService, cfg)

	t.Run("full registration and login flow", func(t *testing.T) {
		// Register a user
		registerData := &models.RegisterRequest{
			Username: "integrationuser",
			Name:     "Integration Test User",
			Email:    "integration@test.com",
			Password: "password123",
			Role:     "author",
		}

		registerResult, err := authService.Register(registerData)
		require.NoError(t, err)
		assert.NotNil(t, registerResult)
		assert.Equal(t, "Integration Test User", registerResult.Name)
		assert.Equal(t, "integration@test.com", registerResult.Email)

		// Login with the same credentials
		loginData := &models.LoginRequest{
			Email:    "integration@test.com",
			Password: "password123",
		}

		loginResult, err := authService.Login(loginData)
		require.NoError(t, err)
		assert.NotNil(t, loginResult)
		assert.NotEmpty(t, loginResult.AccessToken)
		assert.NotEmpty(t, loginResult.RefreshToken)
		assert.Equal(t, "Integration Test User", loginResult.User.Name)

		// Change password
		changePasswordData := &models.ChangePasswordRequest{
			CurrentPassword: "password123",
			NewPassword:     "newpassword456",
		}

		err = authService.ChangePassword(registerResult.ID, changePasswordData)
		require.NoError(t, err)

		// Login with new password
		loginData.Password = "newpassword456"
		loginResult2, err := authService.Login(loginData)
		require.NoError(t, err)
		assert.NotNil(t, loginResult2)
		assert.NotEmpty(t, loginResult2.AccessToken)
	})
}
