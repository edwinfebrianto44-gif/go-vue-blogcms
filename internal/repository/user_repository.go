package repository

import (
	"context"

	"github.com/your-username/go-vue-blogcms/internal/models"
	"gorm.io/gorm"
)

type UserRepository interface {
	Create(ctx context.Context, user *models.User) (*models.User, error)
	GetByID(ctx context.Context, id uint) (*models.User, error)
	GetByEmail(ctx context.Context, email string) (*models.User, error)
	GetByUsername(ctx context.Context, username string) (*models.User, error)
	Update(ctx context.Context, user *models.User) error
	Delete(ctx context.Context, id uint) error
	List(ctx context.Context, offset, limit int) ([]*models.User, error)
	GetCount(ctx context.Context) (int64, error)
}

type userRepository struct {
	db *gorm.DB
}

func NewUserRepository(db *gorm.DB) UserRepository {
	return &userRepository{db: db}
}

func (r *userRepository) Create(ctx context.Context, user *models.User) (*models.User, error) {
	if err := r.db.WithContext(ctx).Create(user).Error; err != nil {
		return nil, err
	}
	return user, nil
}

func (r *userRepository) GetByID(ctx context.Context, id uint) (*models.User, error) {
	var user models.User
	err := r.db.WithContext(ctx).First(&user, id).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) GetByEmail(ctx context.Context, email string) (*models.User, error) {
	var user models.User
	err := r.db.WithContext(ctx).Where("email = ?", email).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) GetByUsername(ctx context.Context, username string) (*models.User, error) {
	var user models.User
	err := r.db.WithContext(ctx).Where("username = ?", username).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) Update(ctx context.Context, user *models.User) error {
	return r.db.WithContext(ctx).Save(user).Error
}

func (r *userRepository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Delete(&models.User{}, id).Error
}

func (r *userRepository) List(ctx context.Context, offset, limit int) ([]*models.User, error) {
	var users []*models.User
	err := r.db.WithContext(ctx).Offset(offset).Limit(limit).Find(&users).Error
	return users, err
}

func (r *userRepository) GetCount(ctx context.Context) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&models.User{}).Count(&count).Error
	return count, err
}
