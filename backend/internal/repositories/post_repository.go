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
	Search(req *models.PostSearchRequest) ([]models.Post, int64, error)
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
		switch key {
		case "status":
			query = query.Where("status = ?", value)
		case "category_id":
			query = query.Where("category_id = ?", value)
		case "author_id":
			query = query.Where("author_id = ?", value)
		}
	}

	// Count total records
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// Apply pagination and get results
	err := query.Order("created_at DESC").Offset(offset).Limit(perPage).Find(&posts).Error
	return posts, total, err
}

// Search posts with full-text search and advanced filtering
func (r *postRepository) Search(req *models.PostSearchRequest) ([]models.Post, int64, error) {
	var posts []models.Post
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
	query := r.db.Model(&models.Post{}).Preload("Category").Preload("Author")

	// Apply full-text search if query is provided
	if req.Query != "" {
		// Use MySQL FULLTEXT search for better relevance
		query = query.Where("MATCH(title, content) AGAINST(? IN NATURAL LANGUAGE MODE)", req.Query)
	}

	// Apply filters
	if req.CategoryID > 0 {
		query = query.Where("category_id = ?", req.CategoryID)
	}
	if req.AuthorID > 0 {
		query = query.Where("author_id = ?", req.AuthorID)
	}
	if req.Status != "" {
		query = query.Where("status = ?", req.Status)
	}

	// Count total records
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// Apply sorting
	orderClause := req.Sort + " " + req.Order
	
	// If we're doing full-text search, we might want to order by relevance first
	if req.Query != "" {
		// For full-text search, we can order by relevance score
		query = query.Select("*, MATCH(title, content) AGAINST(? IN NATURAL LANGUAGE MODE) as relevance_score", req.Query)
		if req.Sort == "created_at" && req.Order == "desc" {
			// Default sort for search: relevance first, then created_at
			orderClause = "relevance_score DESC, created_at DESC"
		} else {
			orderClause = "relevance_score DESC, " + orderClause
		}
	}

	// Apply pagination and get results
	err := query.Order(orderClause).Offset(offset).Limit(req.Limit).Find(&posts).Error
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
