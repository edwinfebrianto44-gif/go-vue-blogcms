package services

import (
	"errors"

	"backend/internal/config"
	"backend/internal/models"
	"backend/internal/repositories"

	"gorm.io/gorm"
)

type AuthService interface {
	Register(req *models.RegisterRequest) (*models.User, error)
	Login(req *models.LoginRequest) (*models.AuthResponse, error)
	RefreshToken(req *models.RefreshTokenRequest) (*models.RefreshTokenResponse, error)
	Logout(userID uint, refreshToken string) error
	LogoutAll(userID uint) error
	ChangePassword(userID uint, req *models.ChangePasswordRequest) error
	GetProfile(userID uint) (*models.User, error)
	UpdateProfile(userID uint, req *models.UpdateProfileRequest) (*models.User, error)
}

type authService struct {
	userRepo repositories.UserRepository
	jwtService JWTService
	cfg      *config.Config
}

func NewAuthService(userRepo repositories.UserRepository, jwtService JWTService, cfg *config.Config) AuthService {
	return &authService{
		userRepo: userRepo,
		jwtService: jwtService,
		cfg:      cfg,
	}
}

func (s *authService) Register(req *models.RegisterRequest) (*models.User, error) {
	// Check if username already exists
	if _, err := s.userRepo.GetByUsername(req.Username); err == nil {
		return nil, errors.New("username already exists")
	}

	// Check if email already exists
	if _, err := s.userRepo.GetByEmail(req.Email); err == nil {
		return nil, errors.New("email already exists")
	}

	// Hash password using JWT service
	hashedPassword, err := s.jwtService.HashPassword(req.Password)
	if err != nil {
		return nil, errors.New("failed to process password")
	}

	// Set default role if not provided
	role := req.Role
	if role == "" {
		role = "author"
	}

	user := &models.User{
		Username: req.Username,
		Email:    req.Email,
		Name:     req.Name,
		Password: hashedPassword,
		Role:     role,
	}

	if err := s.userRepo.Create(user); err != nil {
		return nil, errors.New("failed to create user")
	}

	// Remove password from response
	user.Password = ""
	return user, nil
}

func (s *authService) Login(req *models.LoginRequest) (*models.AuthResponse, error) {
	// Get user by email (changed from username to email)
	user, err := s.userRepo.GetByEmail(req.Email)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("invalid email or password")
		}
		return nil, errors.New("authentication failed")
	}

	// Verify password using JWT service
	if !s.jwtService.CheckPassword(req.Password, user.Password) {
		return nil, errors.New("invalid email or password")
	}

	// Generate token pair
	authResponse, err := s.jwtService.GenerateTokenPair(user)
	if err != nil {
		return nil, errors.New("failed to generate authentication tokens")
	}

	// Remove password from response
	authResponse.User.Password = ""
	return authResponse, nil
}

func (s *authService) RefreshToken(req *models.RefreshTokenRequest) (*models.RefreshTokenResponse, error) {
	refreshResponse, err := s.jwtService.RefreshAccessToken(req.RefreshToken)
	if err != nil {
		return nil, errors.New("invalid or expired refresh token")
	}

	return refreshResponse, nil
}

func (s *authService) Logout(userID uint, refreshToken string) error {
	if refreshToken != "" {
		err := s.jwtService.RevokeRefreshToken(refreshToken)
		if err != nil {
			// Log error but don't fail logout
		}
	}
	return nil
}

func (s *authService) LogoutAll(userID uint) error {
	return s.jwtService.RevokeAllUserTokens(userID)
}

func (s *authService) ChangePassword(userID uint, req *models.ChangePasswordRequest) error {
	// Get current user
	user, err := s.userRepo.GetByID(userID)
	if err != nil {
		return errors.New("user not found")
	}

	// Verify current password
	if !s.jwtService.CheckPassword(req.CurrentPassword, user.Password) {
		return errors.New("current password is incorrect")
	}

	// Hash new password
	hashedPassword, err := s.jwtService.HashPassword(req.NewPassword)
	if err != nil {
		return errors.New("failed to process new password")
	}

	// Update password
	user.Password = hashedPassword
	if err := s.userRepo.Update(user); err != nil {
		return errors.New("failed to update password")
	}

	// Revoke all existing tokens to force re-login
	s.jwtService.RevokeAllUserTokens(userID)

	return nil
}

func (s *authService) GetProfile(userID uint) (*models.User, error) {
	user, err := s.userRepo.GetByID(userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("user not found")
		}
		return nil, errors.New("failed to get user profile")
	}

	// Remove password from response
	user.Password = ""
	return user, nil
}

func (s *authService) UpdateProfile(userID uint, req *models.UpdateProfileRequest) (*models.User, error) {
	user, err := s.userRepo.GetByID(userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("user not found")
		}
		return nil, errors.New("failed to get user profile")
	}

	// Update fields if provided
	if req.Name != nil {
		user.Name = *req.Name
	}
	if req.Username != nil {
		// Check if username is already taken by another user
		existingUser, err := s.userRepo.GetByUsername(*req.Username)
		if err == nil && existingUser.ID != userID {
			return nil, errors.New("username already exists")
		}
		user.Username = *req.Username
	}
	if req.Email != nil {
		// Check if email is already taken by another user
		existingUser, err := s.userRepo.GetByEmail(*req.Email)
		if err == nil && existingUser.ID != userID {
			return nil, errors.New("email already exists")
		}
		user.Email = *req.Email
	}

	if err := s.userRepo.Update(user); err != nil {
		return nil, errors.New("failed to update profile")
	}

	// Remove password from response
	user.Password = ""
	return user, nil
}
