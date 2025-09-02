package services

import (
	"context"
	"errors"

	"github.com/your-username/go-vue-blogcms/internal/models"
	"github.com/your-username/go-vue-blogcms/internal/repository"
)

type UserService struct {
	userRepo repository.UserRepository
}

func NewUserService(userRepo repository.UserRepository) *UserService {
	return &UserService{
		userRepo: userRepo,
	}
}

func (s *UserService) CreateUser(ctx context.Context, user *models.User) (*models.User, error) {
	// Check if user with email already exists
	existingUser, err := s.userRepo.GetByEmail(ctx, user.Email)
	if err == nil && existingUser != nil {
		return nil, errors.New("user with this email already exists")
	}

	// Check if user with username already exists
	existingUser, err = s.userRepo.GetByUsername(ctx, user.Username)
	if err == nil && existingUser != nil {
		return nil, errors.New("user with this username already exists")
	}

	return s.userRepo.Create(ctx, user)
}

func (s *UserService) GetUserByID(ctx context.Context, id uint) (*models.User, error) {
	return s.userRepo.GetByID(ctx, id)
}

func (s *UserService) GetUserByEmail(ctx context.Context, email string) (*models.User, error) {
	return s.userRepo.GetByEmail(ctx, email)
}

func (s *UserService) GetUserByUsername(ctx context.Context, username string) (*models.User, error) {
	return s.userRepo.GetByUsername(ctx, username)
}

func (s *UserService) UpdateUser(ctx context.Context, user *models.User) error {
	return s.userRepo.Update(ctx, user)
}

func (s *UserService) DeleteUser(ctx context.Context, id uint) error {
	return s.userRepo.Delete(ctx, id)
}

func (s *UserService) GetUserCount(ctx context.Context) (int64, error) {
	return s.userRepo.GetCount(ctx)
}

func (s *UserService) ListUsers(ctx context.Context, offset, limit int) ([]*models.User, error) {
	return s.userRepo.List(ctx, offset, limit)
}
