package services

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"os"
	"strconv"
	"time"

	"backend/internal/models"
	"backend/internal/repositories"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

type JWTService interface {
	GenerateTokenPair(user *models.User) (*models.AuthResponse, error)
	ValidateAccessToken(tokenString string) (*models.JWTClaims, error)
	ValidateRefreshToken(tokenString string) (*models.JWTClaims, error)
	RefreshAccessToken(refreshToken string) (*models.RefreshTokenResponse, error)
	RevokeRefreshToken(tokenString string) error
	RevokeAllUserTokens(userID uint) error
	HashPassword(password string) (string, error)
	CheckPassword(password, hash string) bool
}

type jwtService struct {
	secretKey            []byte
	accessTokenDuration  time.Duration
	refreshTokenDuration time.Duration
	refreshTokenRepo     repositories.RefreshTokenRepository
}

func NewJWTService(refreshTokenRepo repositories.RefreshTokenRepository) JWTService {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		secret = "your-super-secret-jwt-key-change-this-in-production"
	}

	accessDuration := 15 * time.Minute // 15 minutes
	if envDuration := os.Getenv("JWT_ACCESS_DURATION"); envDuration != "" {
		if duration, err := time.ParseDuration(envDuration); err == nil {
			accessDuration = duration
		}
	}

	refreshDuration := 7 * 24 * time.Hour // 7 days
	if envDuration := os.Getenv("JWT_REFRESH_DURATION"); envDuration != "" {
		if duration, err := time.ParseDuration(envDuration); err == nil {
			refreshDuration = duration
		}
	}

	return &jwtService{
		secretKey:            []byte(secret),
		accessTokenDuration:  accessDuration,
		refreshTokenDuration: refreshDuration,
		refreshTokenRepo:     refreshTokenRepo,
	}
}

func (s *jwtService) GenerateTokenPair(user *models.User) (*models.AuthResponse, error) {
	now := time.Now()
	
	// Generate access token
	accessClaims := &models.JWTClaims{
		UserID:   user.ID,
		Email:    user.Email,
		Username: user.Username,
		Role:     user.Role,
		Type:     "access",
		IssuedAt: now.Unix(),
		ExpiresAt: now.Add(s.accessTokenDuration).Unix(),
	}

	accessToken := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id":  accessClaims.UserID,
		"email":    accessClaims.Email,
		"username": accessClaims.Username,
		"role":     accessClaims.Role,
		"type":     accessClaims.Type,
		"iat":      accessClaims.IssuedAt,
		"exp":      accessClaims.ExpiresAt,
	})

	accessTokenString, err := accessToken.SignedString(s.secretKey)
	if err != nil {
		return nil, err
	}

	// Generate refresh token
	refreshTokenString, err := s.generateSecureToken()
	if err != nil {
		return nil, err
	}

	// Store refresh token in database
	refreshToken := &models.RefreshToken{
		UserID:    user.ID,
		Token:     refreshTokenString,
		ExpiresAt: now.Add(s.refreshTokenDuration),
		CreatedAt: now,
		UpdatedAt: now,
		IsRevoked: false,
	}

	if err := s.refreshTokenRepo.Create(refreshToken); err != nil {
		return nil, err
	}

	return &models.AuthResponse{
		AccessToken:  accessTokenString,
		RefreshToken: refreshTokenString,
		TokenType:    "Bearer",
		ExpiresIn:    int64(s.accessTokenDuration.Seconds()),
		User:         *user,
	}, nil
}

func (s *jwtService) ValidateAccessToken(tokenString string) (*models.JWTClaims, error) {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("invalid signing method")
		}
		return s.secretKey, nil
	})

	if err != nil {
		return nil, err
	}

	if !token.Valid {
		return nil, errors.New("invalid token")
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, errors.New("invalid token claims")
	}

	// Verify token type
	if tokenType, ok := claims["type"].(string); !ok || tokenType != "access" {
		return nil, errors.New("invalid token type")
	}

	// Check expiration
	if exp, ok := claims["exp"].(float64); ok {
		if time.Now().Unix() > int64(exp) {
			return nil, errors.New("token has expired")
		}
	}

	jwtClaims := &models.JWTClaims{
		Type: "access",
	}

	if userID, ok := claims["user_id"].(float64); ok {
		jwtClaims.UserID = uint(userID)
	}
	if email, ok := claims["email"].(string); ok {
		jwtClaims.Email = email
	}
	if username, ok := claims["username"].(string); ok {
		jwtClaims.Username = username
	}
	if role, ok := claims["role"].(string); ok {
		jwtClaims.Role = role
	}
	if iat, ok := claims["iat"].(float64); ok {
		jwtClaims.IssuedAt = int64(iat)
	}
	if exp, ok := claims["exp"].(float64); ok {
		jwtClaims.ExpiresAt = int64(exp)
	}

	return jwtClaims, nil
}

func (s *jwtService) ValidateRefreshToken(tokenString string) (*models.JWTClaims, error) {
	refreshToken, err := s.refreshTokenRepo.GetByToken(tokenString)
	if err != nil {
		return nil, errors.New("invalid refresh token")
	}

	if refreshToken.IsRevoked {
		return nil, errors.New("refresh token has been revoked")
	}

	if time.Now().After(refreshToken.ExpiresAt) {
		return nil, errors.New("refresh token has expired")
	}

	return &models.JWTClaims{
		UserID: refreshToken.UserID,
		Type:   "refresh",
	}, nil
}

func (s *jwtService) RefreshAccessToken(refreshToken string) (*models.RefreshTokenResponse, error) {
	// Validate refresh token
	claims, err := s.ValidateRefreshToken(refreshToken)
	if err != nil {
		return nil, err
	}

	// Get user details
	refreshTokenModel, err := s.refreshTokenRepo.GetByToken(refreshToken)
	if err != nil {
		return nil, err
	}

	user := refreshTokenModel.User
	if user == nil {
		return nil, errors.New("user not found")
	}

	// Generate new token pair
	authResponse, err := s.GenerateTokenPair(user)
	if err != nil {
		return nil, err
	}

	// Revoke old refresh token
	if err := s.RevokeRefreshToken(refreshToken); err != nil {
		// Log error but don't fail the request
	}

	return &models.RefreshTokenResponse{
		AccessToken:  authResponse.AccessToken,
		RefreshToken: authResponse.RefreshToken,
		TokenType:    authResponse.TokenType,
		ExpiresIn:    authResponse.ExpiresIn,
	}, nil
}

func (s *jwtService) RevokeRefreshToken(tokenString string) error {
	return s.refreshTokenRepo.RevokeToken(tokenString)
}

func (s *jwtService) RevokeAllUserTokens(userID uint) error {
	return s.refreshTokenRepo.RevokeAllUserTokens(userID)
}

func (s *jwtService) HashPassword(password string) (string, error) {
	return utils.HashPassword(password)
}

func (s *jwtService) CheckPassword(password, hash string) bool {
	return utils.VerifyPassword(password, hash)
}

func (s *jwtService) generateSecureToken() (string, error) {
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}

// Helper function to extract token from Authorization header
func ExtractTokenFromHeader(authHeader string) string {
	if authHeader == "" {
		return ""
	}

	// Check if header starts with "Bearer "
	if len(authHeader) > 7 && authHeader[:7] == "Bearer " {
		return authHeader[7:]
	}

	return ""
}

// Helper function to get JWT duration from environment
func getJWTDurationFromEnv(envKey string, defaultDuration time.Duration) time.Duration {
	envValue := os.Getenv(envKey)
	if envValue == "" {
		return defaultDuration
	}

	// Try parsing as duration first (e.g., "15m", "1h", "24h")
	if duration, err := time.ParseDuration(envValue); err == nil {
		return duration
	}

	// Try parsing as minutes (for backward compatibility)
	if minutes, err := strconv.Atoi(envValue); err == nil {
		return time.Duration(minutes) * time.Minute
	}

	return defaultDuration
}
