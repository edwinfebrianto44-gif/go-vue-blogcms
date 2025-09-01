package repositories

import (
	"backend/internal/models"

	"gorm.io/gorm"
)

type CommentRepository interface {
	Create(comment *models.Comment) error
	GetByID(id uint) (*models.Comment, error)
	Update(comment *models.Comment) error
	Delete(id uint) error
	List(page, perPage int, filters map[string]interface{}) ([]models.Comment, int64, error)
	GetByPost(postID uint, page, perPage int) ([]models.Comment, int64, error)
	GetByUser(userID uint, page, perPage int) ([]models.Comment, int64, error)
}

type commentRepository struct {
	db *gorm.DB
}

func NewCommentRepository(db *gorm.DB) CommentRepository {
	return &commentRepository{db: db}
}

func (r *commentRepository) Create(comment *models.Comment) error {
	return r.db.Create(comment).Error
}

func (r *commentRepository) GetByID(id uint) (*models.Comment, error) {
	var comment models.Comment
	err := r.db.Preload("Post").Preload("User").First(&comment, id).Error
	if err != nil {
		return nil, err
	}
	return &comment, nil
}

func (r *commentRepository) Update(comment *models.Comment) error {
	return r.db.Save(comment).Error
}

func (r *commentRepository) Delete(id uint) error {
	return r.db.Delete(&models.Comment{}, id).Error
}

func (r *commentRepository) List(page, perPage int, filters map[string]interface{}) ([]models.Comment, int64, error) {
	var comments []models.Comment
	var total int64

	offset := (page - 1) * perPage
	query := r.db.Model(&models.Comment{}).Preload("Post").Preload("User")

	// Apply filters
	for key, value := range filters {
		query = query.Where(key+" = ?", value)
	}

	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	err := query.Offset(offset).Limit(perPage).Find(&comments).Error
	return comments, total, err
}

func (r *commentRepository) GetByPost(postID uint, page, perPage int) ([]models.Comment, int64, error) {
	var comments []models.Comment
	var total int64

	offset := (page - 1) * perPage

	if err := r.db.Model(&models.Comment{}).Where("post_id = ?", postID).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	err := r.db.Preload("User").Where("post_id = ?", postID).
		Offset(offset).Limit(perPage).Find(&comments).Error
	return comments, total, err
}

func (r *commentRepository) GetByUser(userID uint, page, perPage int) ([]models.Comment, int64, error) {
	var comments []models.Comment
	var total int64

	offset := (page - 1) * perPage

	if err := r.db.Model(&models.Comment{}).Where("user_id = ?", userID).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	err := r.db.Preload("Post").Where("user_id = ?", userID).
		Offset(offset).Limit(perPage).Find(&comments).Error
	return comments, total, err
}
