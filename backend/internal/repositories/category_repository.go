package repositories

import (
	"backend/internal/models"

	"gorm.io/gorm"
)

type CategoryRepository interface {
	Create(category *models.Category) error
	GetByID(id uint) (*models.Category, error)
	GetBySlug(slug string) (*models.Category, error)
	Update(category *models.Category) error
	Delete(id uint) error
	List(page, perPage int) ([]models.Category, int64, error)
	Search(req *models.CategorySearchRequest) ([]models.Category, int64, error)
}

type categoryRepository struct {
	db *gorm.DB
}

func NewCategoryRepository(db *gorm.DB) CategoryRepository {
	return &categoryRepository{db: db}
}

func (r *categoryRepository) Create(category *models.Category) error {
	return r.db.Create(category).Error
}

func (r *categoryRepository) GetByID(id uint) (*models.Category, error) {
	var category models.Category
	err := r.db.First(&category, id).Error
	if err != nil {
		return nil, err
	}
	return &category, nil
}

func (r *categoryRepository) GetBySlug(slug string) (*models.Category, error) {
	var category models.Category
	err := r.db.Where("slug = ?", slug).First(&category).Error
	if err != nil {
		return nil, err
	}
	return &category, nil
}

func (r *categoryRepository) Update(category *models.Category) error {
	return r.db.Save(category).Error
}

func (r *categoryRepository) Delete(id uint) error {
	return r.db.Delete(&models.Category{}, id).Error
}

func (r *categoryRepository) List(page, perPage int) ([]models.Category, int64, error) {
	var categories []models.Category
	var total int64

	offset := (page - 1) * perPage

	if err := r.db.Model(&models.Category{}).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	err := r.db.Order("created_at DESC").Offset(offset).Limit(perPage).Find(&categories).Error
	return categories, total, err
}

// Search categories with filtering and sorting
func (r *categoryRepository) Search(req *models.CategorySearchRequest) ([]models.Category, int64, error) {
	var categories []models.Category
	var total int64

	// Set defaults
	if req.Page <= 0 {
		req.Page = 1
	}
	if req.Limit <= 0 {
		req.Limit = 10
	}
	if req.Limit > 100 {
		req.Limit = 100
	}
	if req.Sort == "" {
		req.Sort = "created_at"
	}
	if req.Order == "" {
		req.Order = "desc"
	}

	offset := (req.Page - 1) * req.Limit
	query := r.db.Model(&models.Category{})

	// Apply search filter if query is provided
	if req.Query != "" {
		query = query.Where("name LIKE ? OR description LIKE ?", "%"+req.Query+"%", "%"+req.Query+"%")
	}

	// Count total records
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// Apply sorting and pagination
	orderClause := req.Sort + " " + req.Order
	err := query.Order(orderClause).Offset(offset).Limit(req.Limit).Find(&categories).Error
	return categories, total, err
}
