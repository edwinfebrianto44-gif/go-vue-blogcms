package services

import (
	"errors"

	"backend/internal/models"
	"backend/internal/repositories"
	"backend/pkg/utils"

	"gorm.io/gorm"
)

type PostService interface {
	Create(req *models.CreatePostRequest, authorID uint) (*models.Post, error)
	GetByID(id uint) (*models.Post, error)
	GetBySlug(slug string) (*models.Post, error)
	Update(id uint, req *models.UpdatePostRequest, userID uint, userRole string) (*models.Post, error)
	Delete(id uint, userID uint, userRole string) error
	List(page, perPage int, filters map[string]interface{}) ([]models.Post, int64, error)
	Search(req *models.PostSearchRequest) ([]models.Post, int64, error)
	GetByAuthor(authorID uint, page, perPage int) ([]models.Post, int64, error)
	GetByCategory(categoryID uint, page, perPage int) ([]models.Post, int64, error)
}

type postService struct {
	postRepo     repositories.PostRepository
	userRepo     repositories.UserRepository
	categoryRepo repositories.CategoryRepository
}

func NewPostService(postRepo repositories.PostRepository, userRepo repositories.UserRepository, categoryRepo repositories.CategoryRepository) PostService {
	return &postService{
		postRepo:     postRepo,
		userRepo:     userRepo,
		categoryRepo: categoryRepo,
	}
}

func (s *postService) Create(req *models.CreatePostRequest, authorID uint) (*models.Post, error) {
	// Verify category exists
	if _, err := s.categoryRepo.GetByID(req.CategoryID); err != nil {
		return nil, errors.New("category not found")
	}

	// Generate slug from title
	slug := utils.GenerateSlug(req.Title)

	// Set default status if not provided
	status := req.Status
	if status == "" {
		status = "draft"
	}

	post := &models.Post{
		Title:      req.Title,
		Slug:       slug,
		Content:    req.Content,
		Excerpt:    req.Excerpt,
		CategoryID: req.CategoryID,
		AuthorID:   authorID,
		Status:     status,
	}

	if err := s.postRepo.Create(post); err != nil {
		return nil, err
	}

	return s.postRepo.GetByID(post.ID)
}

func (s *postService) GetByID(id uint) (*models.Post, error) {
	return s.postRepo.GetByID(id)
}

func (s *postService) GetBySlug(slug string) (*models.Post, error) {
	return s.postRepo.GetBySlug(slug)
}

func (s *postService) Update(id uint, req *models.UpdatePostRequest, userID uint, userRole string) (*models.Post, error) {
	// Get existing post
	post, err := s.postRepo.GetByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("post not found")
		}
		return nil, err
	}

	// Check permission - authors can only edit their own posts, admins can edit any
	if userRole != "admin" && post.AuthorID != userID {
		return nil, errors.New("you don't have permission to update this post")
	}

	// Update fields if provided
	if req.Title != "" {
		post.Title = req.Title
		post.Slug = utils.GenerateSlug(req.Title)
	}
	if req.Content != "" {
		post.Content = req.Content
	}
	if req.Excerpt != "" {
		post.Excerpt = req.Excerpt
	}
	if req.CategoryID != 0 {
		// Verify new category exists
		if _, err := s.categoryRepo.GetByID(req.CategoryID); err != nil {
			return nil, errors.New("category not found")
		}
		post.CategoryID = req.CategoryID
	}
	if req.Status != "" {
		post.Status = req.Status
	}

	if err := s.postRepo.Update(post); err != nil {
		return nil, err
	}

	return s.postRepo.GetByID(post.ID)
}

func (s *postService) Delete(id uint, userID uint, userRole string) error {
	// Get existing post
	post, err := s.postRepo.GetByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return errors.New("post not found")
		}
		return err
	}

	// Check permission
	if userRole != "admin" && post.AuthorID != userID {
		return errors.New("you don't have permission to delete this post")
	}

	return s.postRepo.Delete(id)
}

func (s *postService) List(page, perPage int, filters map[string]interface{}) ([]models.Post, int64, error) {
	return s.postRepo.List(page, perPage, filters)
}

func (s *postService) Search(req *models.PostSearchRequest) ([]models.Post, int64, error) {
	return s.postRepo.Search(req)
}

func (s *postService) GetByAuthor(authorID uint, page, perPage int) ([]models.Post, int64, error) {
	return s.postRepo.GetByAuthor(authorID, page, perPage)
}

func (s *postService) GetByCategory(categoryID uint, page, perPage int) ([]models.Post, int64, error) {
	return s.postRepo.GetByCategory(categoryID, page, perPage)
}
