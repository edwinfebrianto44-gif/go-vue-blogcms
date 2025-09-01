package services

import (
	"errors"

	"backend/internal/models"
	"backend/internal/repositories"
	"backend/pkg/utils"

	"gorm.io/gorm"
)

type CategoryService interface {
	Create(req *models.CreateCategoryRequest) (*models.Category, error)
	GetByID(id uint) (*models.Category, error)
	GetBySlug(slug string) (*models.Category, error)
	Update(id uint, req *models.UpdateCategoryRequest) (*models.Category, error)
	Delete(id uint) error
	List(page, perPage int) ([]models.Category, int64, error)
}

type categoryService struct {
	categoryRepo repositories.CategoryRepository
}

func NewCategoryService(categoryRepo repositories.CategoryRepository) CategoryService {
	return &categoryService{
		categoryRepo: categoryRepo,
	}
}

func (s *categoryService) Create(req *models.CreateCategoryRequest) (*models.Category, error) {
	// Generate slug from name
	slug := utils.GenerateSlug(req.Name)

	category := &models.Category{
		Name:        req.Name,
		Slug:        slug,
		Description: req.Description,
	}

	if err := s.categoryRepo.Create(category); err != nil {
		return nil, err
	}

	return category, nil
}

func (s *categoryService) GetByID(id uint) (*models.Category, error) {
	return s.categoryRepo.GetByID(id)
}

func (s *categoryService) GetBySlug(slug string) (*models.Category, error) {
	return s.categoryRepo.GetBySlug(slug)
}

func (s *categoryService) Update(id uint, req *models.UpdateCategoryRequest) (*models.Category, error) {
	// Get existing category
	category, err := s.categoryRepo.GetByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("category not found")
		}
		return nil, err
	}

	// Update fields if provided
	if req.Name != "" {
		category.Name = req.Name
		category.Slug = utils.GenerateSlug(req.Name)
	}
	if req.Description != "" {
		category.Description = req.Description
	}

	if err := s.categoryRepo.Update(category); err != nil {
		return nil, err
	}

	return category, nil
}

func (s *categoryService) Delete(id uint) error {
	// Check if category exists
	if _, err := s.categoryRepo.GetByID(id); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return errors.New("category not found")
		}
		return err
	}

	return s.categoryRepo.Delete(id)
}

func (s *categoryService) List(page, perPage int) ([]models.Category, int64, error) {
	return s.categoryRepo.List(page, perPage)
}
