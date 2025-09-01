package repositories

import (
	"backend/internal/models"

	"gorm.io/gorm"
)

type PostRepository interface {
	Create(post *models.Post) error
	GetByID(id uint) (*models.Post, error)
	GetBySlug(slug string) (*models.Post, error)
	Update(post *models.Post) error
	Delete(id uint) error
	List(page, perPage int, filters map[string]interface{}) ([]models.Post, int64, error)
	GetByAuthor(authorID uint, page, perPage int) ([]models.Post, int64, error)
	GetByCategory(categoryID uint, page, perPage int) ([]models.Post, int64, error)
}

type postRepository struct {
	db *gorm.DB
}

func NewPostRepository(db *gorm.DB) PostRepository {
	return &postRepository{db: db}
}

func (r *postRepository) Create(post *models.Post) error {
	return r.db.Create(post).Error
}

func (r *postRepository) GetByID(id uint) (*models.Post, error) {
	var post models.Post
	err := r.db.Preload("Category").Preload("Author").Preload("Comments").First(&post, id).Error
	if err != nil {
		return nil, err
	}
	return &post, nil
}

func (r *postRepository) GetBySlug(slug string) (*models.Post, error) {
	var post models.Post
	err := r.db.Preload("Category").Preload("Author").Preload("Comments").Where("slug = ?", slug).First(&post).Error
	if err != nil {
		return nil, err
	}
	return &post, nil
}

func (r *postRepository) Update(post *models.Post) error {
	return r.db.Save(post).Error
}

func (r *postRepository) Delete(id uint) error {
	return r.db.Delete(&models.Post{}, id).Error
}

func (r *postRepository) List(page, perPage int, filters map[string]interface{}) ([]models.Post, int64, error) {
	var posts []models.Post
	var total int64

	offset := (page - 1) * perPage
	query := r.db.Model(&models.Post{}).Preload("Category").Preload("Author")

	// Apply filters
	for key, value := range filters {
		query = query.Where(key+" = ?", value)
	}

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	err := query.Offset(offset).Limit(perPage).Find(&posts).Error
	return posts, total, err
}

func (r *postRepository) GetByAuthor(authorID uint, page, perPage int) ([]models.Post, int64, error) {
	var posts []models.Post
	var total int64

	offset := (page - 1) * perPage

	if err := r.db.Model(&models.Post{}).Where("author_id = ?", authorID).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	err := r.db.Preload("Category").Preload("Author").Where("author_id = ?", authorID).
		Offset(offset).Limit(perPage).Find(&posts).Error
	return posts, total, err
}

func (r *postRepository) GetByCategory(categoryID uint, page, perPage int) ([]models.Post, int64, error) {
	var posts []models.Post
	var total int64

	offset := (page - 1) * perPage

	if err := r.db.Model(&models.Post{}).Where("category_id = ?", categoryID).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	err := r.db.Preload("Category").Preload("Author").Where("category_id = ?", categoryID).
		Offset(offset).Limit(perPage).Find(&posts).Error
	return posts, total, err
}
