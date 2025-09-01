package services

import (
	"errors"

	"backend/internal/models"
	"backend/internal/repositories"

	"gorm.io/gorm"
)

type CommentService interface {
	Create(req *models.CreateCommentRequest, userID uint) (*models.Comment, error)
	GetByID(id uint) (*models.Comment, error)
	Update(id uint, req *models.UpdateCommentRequest, userID uint, userRole string) (*models.Comment, error)
	Delete(id uint, userID uint, userRole string) error
	List(page, perPage int, filters map[string]interface{}) ([]models.Comment, int64, error)
	GetByPost(postID uint, page, perPage int) ([]models.Comment, int64, error)
	GetByUser(userID uint, page, perPage int) ([]models.Comment, int64, error)
}

type commentService struct {
	commentRepo repositories.CommentRepository
	postRepo    repositories.PostRepository
}

func NewCommentService(commentRepo repositories.CommentRepository, postRepo repositories.PostRepository) CommentService {
	return &commentService{
		commentRepo: commentRepo,
		postRepo:    postRepo,
	}
}

func (s *commentService) Create(req *models.CreateCommentRequest, userID uint) (*models.Comment, error) {
	// Verify post exists
	if _, err := s.postRepo.GetByID(req.PostID); err != nil {
		return nil, errors.New("post not found")
	}

	comment := &models.Comment{
		PostID:  req.PostID,
		UserID:  userID,
		Content: req.Content,
		Status:  "pending",
	}

	if err := s.commentRepo.Create(comment); err != nil {
		return nil, err
	}

	return s.commentRepo.GetByID(comment.ID)
}

func (s *commentService) GetByID(id uint) (*models.Comment, error) {
	return s.commentRepo.GetByID(id)
}

func (s *commentService) Update(id uint, req *models.UpdateCommentRequest, userID uint, userRole string) (*models.Comment, error) {
	// Get existing comment
	comment, err := s.commentRepo.GetByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("comment not found")
		}
		return nil, err
	}

	// Check permission - users can only edit their own comments, admins can edit any
	if userRole != "admin" && comment.UserID != userID {
		return nil, errors.New("you don't have permission to update this comment")
	}

	// Update fields if provided
	if req.Content != "" {
		comment.Content = req.Content
	}
	
	// Only admins can change status
	if req.Status != "" && userRole == "admin" {
		comment.Status = req.Status
	}

	if err := s.commentRepo.Update(comment); err != nil {
		return nil, err
	}

	return s.commentRepo.GetByID(comment.ID)
}

func (s *commentService) Delete(id uint, userID uint, userRole string) error {
	// Get existing comment
	comment, err := s.commentRepo.GetByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return errors.New("comment not found")
		}
		return err
	}

	// Check permission
	if userRole != "admin" && comment.UserID != userID {
		return errors.New("you don't have permission to delete this comment")
	}

	return s.commentRepo.Delete(id)
}

func (s *commentService) List(page, perPage int, filters map[string]interface{}) ([]models.Comment, int64, error) {
	return s.commentRepo.List(page, perPage, filters)
}

func (s *commentService) GetByPost(postID uint, page, perPage int) ([]models.Comment, int64, error) {
	return s.commentRepo.GetByPost(postID, page, perPage)
}

func (s *commentService) GetByUser(userID uint, page, perPage int) ([]models.Comment, int64, error) {
	return s.commentRepo.GetByUser(userID, page, perPage)
}
