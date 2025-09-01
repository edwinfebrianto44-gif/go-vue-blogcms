package repositories

import (
	"backend/internal/models"
	"time"

	"gorm.io/gorm"
)

type RefreshTokenRepository interface {
	Create(token *models.RefreshToken) error
	GetByToken(token string) (*models.RefreshToken, error)
	GetByUserID(userID uint) ([]*models.RefreshToken, error)
	RevokeToken(token string) error
	RevokeAllUserTokens(userID uint) error
	DeleteExpiredTokens() error
	Update(token *models.RefreshToken) error
	Delete(id uint) error
}

type refreshTokenRepository struct {
	db *gorm.DB
}

func NewRefreshTokenRepository(db *gorm.DB) RefreshTokenRepository {
	return &refreshTokenRepository{
		db: db,
	}
}

func (r *refreshTokenRepository) Create(token *models.RefreshToken) error {
	return r.db.Create(token).Error
}

func (r *refreshTokenRepository) GetByToken(tokenString string) (*models.RefreshToken, error) {
	var token models.RefreshToken
	err := r.db.Preload("User").Where("token = ? AND is_revoked = ? AND expires_at > ?", 
		tokenString, false, time.Now()).First(&token).Error
	if err != nil {
		return nil, err
	}
	return &token, nil
}

func (r *refreshTokenRepository) GetByUserID(userID uint) ([]*models.RefreshToken, error) {
	var tokens []*models.RefreshToken
	err := r.db.Where("user_id = ? AND is_revoked = ? AND expires_at > ?", 
		userID, false, time.Now()).Find(&tokens).Error
	return tokens, err
}

func (r *refreshTokenRepository) RevokeToken(tokenString string) error {
	return r.db.Model(&models.RefreshToken{}).
		Where("token = ?", tokenString).
		Update("is_revoked", true).Error
}

func (r *refreshTokenRepository) RevokeAllUserTokens(userID uint) error {
	return r.db.Model(&models.RefreshToken{}).
		Where("user_id = ? AND is_revoked = ?", userID, false).
		Update("is_revoked", true).Error
}

func (r *refreshTokenRepository) DeleteExpiredTokens() error {
	return r.db.Where("expires_at < ? OR is_revoked = ?", time.Now(), true).
		Delete(&models.RefreshToken{}).Error
}

func (r *refreshTokenRepository) Update(token *models.RefreshToken) error {
	return r.db.Save(token).Error
}

func (r *refreshTokenRepository) Delete(id uint) error {
	return r.db.Delete(&models.RefreshToken{}, id).Error
}
