package services

import (
	"testing"

	"backend/internal/models"
	"backend/internal/testutils"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
	"gorm.io/gorm"
)

// MockPostRepository is a mock implementation of PostRepository
type MockPostRepository struct {
	mock.Mock
}

func (m *MockPostRepository) Create(post *models.Post) error {
	args := m.Called(post)
	return args.Error(0)
}

func (m *MockPostRepository) GetByID(id uint) (*models.Post, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Post), args.Error(1)
}

func (m *MockPostRepository) GetBySlug(slug string) (*models.Post, error) {
	args := m.Called(slug)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Post), args.Error(1)
}

func (m *MockPostRepository) Update(post *models.Post) error {
	args := m.Called(post)
	return args.Error(0)
}

func (m *MockPostRepository) Delete(id uint) error {
	args := m.Called(id)
	return args.Error(0)
}

func (m *MockPostRepository) List(page, perPage int, filters map[string]interface{}) ([]models.Post, int64, error) {
	args := m.Called(page, perPage, filters)
	return args.Get(0).([]models.Post), args.Get(1).(int64), args.Error(2)
}

func (m *MockPostRepository) GetByAuthor(authorID uint, page, perPage int) ([]models.Post, int64, error) {
	args := m.Called(authorID, page, perPage)
	return args.Get(0).([]models.Post), args.Get(1).(int64), args.Error(2)
}

func (m *MockPostRepository) GetByCategory(categoryID uint, page, perPage int) ([]models.Post, int64, error) {
	args := m.Called(categoryID, page, perPage)
	return args.Get(0).([]models.Post), args.Get(1).(int64), args.Error(2)
}

func (m *MockPostRepository) GetPublished(page, perPage int) ([]models.Post, int64, error) {
	args := m.Called(page, perPage)
	return args.Get(0).([]models.Post), args.Get(1).(int64), args.Error(2)
}

// MockCategoryRepository is a mock implementation of CategoryRepository
type MockCategoryRepository struct {
	mock.Mock
}

func (m *MockCategoryRepository) Create(category *models.Category) error {
	args := m.Called(category)
	return args.Error(0)
}

func (m *MockCategoryRepository) GetByID(id uint) (*models.Category, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Category), args.Error(1)
}

func (m *MockCategoryRepository) GetBySlug(slug string) (*models.Category, error) {
	args := m.Called(slug)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Category), args.Error(1)
}

func (m *MockCategoryRepository) Update(category *models.Category) error {
	args := m.Called(category)
	return args.Error(0)
}

func (m *MockCategoryRepository) Delete(id uint) error {
	args := m.Called(id)
	return args.Error(0)
}

func (m *MockCategoryRepository) List(page, perPage int) ([]models.Category, int64, error) {
	args := m.Called(page, perPage)
	return args.Get(0).([]models.Category), args.Get(1).(int64), args.Error(2)
}

func TestPostService_CreatePost(t *testing.T) {
	// Setup
	mockPostRepo := new(MockPostRepository)
	mockUserRepo := new(MockUserRepository)
	mockCategoryRepo := new(MockCategoryRepository)
	postService := NewPostService(mockPostRepo, mockUserRepo, mockCategoryRepo)

	t.Run("successful post creation", func(t *testing.T) {
		// Given
		userID := uint(1)
		createPostData := &models.CreatePostRequest{
			Title:      "Test Post",
			Content:    "This is a test post content that is long enough to meet validation requirements.",
			Excerpt:    "Test excerpt",
			CategoryID: 1,
			Status:     "draft",
		}

		author := &models.User{
			ID:   1,
			Name: "Test Author",
			Role: "author",
		}

		category := &models.Category{
			ID:   1,
			Name: "Test Category",
		}

		// Mock expectations
		mockUserRepo.On("GetByID", userID).Return(author, nil).Once()
		mockCategoryRepo.On("GetByID", uint(1)).Return(category, nil).Once()
		mockPostRepo.On("Create", mock.AnythingOfType("*models.Post")).Run(func(args mock.Arguments) {
			post := args.Get(0).(*models.Post)
			post.ID = 1 // Simulate database assigning ID
		}).Return(nil).Once()

		// When
		result, err := postService.CreatePost(userID, createPostData)

		// Then
		require.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, uint(1), result.ID)
		assert.Equal(t, "Test Post", result.Title)
		assert.Equal(t, "test-post", result.Slug) // Should generate slug
		assert.Equal(t, userID, result.AuthorID)
		assert.Equal(t, uint(1), result.CategoryID)

		mockPostRepo.AssertExpectations(t)
		mockUserRepo.AssertExpectations(t)
		mockCategoryRepo.AssertExpectations(t)
	})

	t.Run("author not found", func(t *testing.T) {
		// Given
		userID := uint(999)
		createPostData := &models.CreatePostRequest{
			Title:      "Test Post",
			Content:    "This is a test post content that is long enough to meet validation requirements.",
			CategoryID: 1,
		}

		// Mock expectations
		mockUserRepo.On("GetByID", userID).Return(nil, gorm.ErrRecordNotFound).Once()

		// When
		result, err := postService.CreatePost(userID, createPostData)

		// Then
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.Equal(t, "author not found", err.Error())

		mockUserRepo.AssertExpectations(t)
	})

	t.Run("category not found", func(t *testing.T) {
		// Given
		userID := uint(1)
		createPostData := &models.CreatePostRequest{
			Title:      "Test Post",
			Content:    "This is a test post content that is long enough to meet validation requirements.",
			CategoryID: 999,
		}

		author := &models.User{
			ID:   1,
			Role: "author",
		}

		// Mock expectations
		mockUserRepo.On("GetByID", userID).Return(author, nil).Once()
		mockCategoryRepo.On("GetByID", uint(999)).Return(nil, gorm.ErrRecordNotFound).Once()

		// When
		result, err := postService.CreatePost(userID, createPostData)

		// Then
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.Equal(t, "category not found", err.Error())

		mockUserRepo.AssertExpectations(t)
		mockCategoryRepo.AssertExpectations(t)
	})
}

func TestPostService_GetPostByID(t *testing.T) {
	// Setup
	mockPostRepo := new(MockPostRepository)
	mockUserRepo := new(MockUserRepository)
	mockCategoryRepo := new(MockCategoryRepository)
	postService := NewPostService(mockPostRepo, mockUserRepo, mockCategoryRepo)

	t.Run("successful get post", func(t *testing.T) {
		// Given
		postID := uint(1)
		expectedPost := &models.Post{
			ID:       1,
			Title:    "Test Post",
			Slug:     "test-post",
			Content:  "Test content",
			AuthorID: 1,
			Status:   "published",
		}

		// Mock expectations
		mockPostRepo.On("GetByID", postID).Return(expectedPost, nil).Once()

		// When
		result, err := postService.GetPostByID(postID)

		// Then
		require.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, expectedPost.ID, result.ID)
		assert.Equal(t, expectedPost.Title, result.Title)

		mockPostRepo.AssertExpectations(t)
	})

	t.Run("post not found", func(t *testing.T) {
		// Given
		postID := uint(999)

		// Mock expectations
		mockPostRepo.On("GetByID", postID).Return(nil, gorm.ErrRecordNotFound).Once()

		// When
		result, err := postService.GetPostByID(postID)

		// Then
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.Equal(t, "post not found", err.Error())

		mockPostRepo.AssertExpectations(t)
	})
}

func TestPostService_UpdatePost(t *testing.T) {
	// Setup
	mockPostRepo := new(MockPostRepository)
	mockUserRepo := new(MockUserRepository)
	mockCategoryRepo := new(MockCategoryRepository)
	postService := NewPostService(mockPostRepo, mockUserRepo, mockCategoryRepo)

	t.Run("successful post update by author", func(t *testing.T) {
		// Given
		postID := uint(1)
		userID := uint(1)
		newTitle := "Updated Test Post"
		updatePostData := &models.UpdatePostRequest{
			Title: &newTitle,
		}

		existingPost := &models.Post{
			ID:       1,
			Title:    "Test Post",
			AuthorID: 1,
			Status:   "draft",
		}

		user := &models.User{
			ID:   1,
			Role: "author",
		}

		// Mock expectations
		mockPostRepo.On("GetByID", postID).Return(existingPost, nil).Once()
		mockUserRepo.On("GetByID", userID).Return(user, nil).Once()
		mockPostRepo.On("Update", mock.AnythingOfType("*models.Post")).Return(nil).Once()

		// When
		result, err := postService.UpdatePost(userID, postID, updatePostData)

		// Then
		require.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, "Updated Test Post", result.Title)

		mockPostRepo.AssertExpectations(t)
		mockUserRepo.AssertExpectations(t)
	})

	t.Run("unauthorized update attempt", func(t *testing.T) {
		// Given
		postID := uint(1)
		userID := uint(2) // Different user
		newTitle := "Updated Test Post"
		updatePostData := &models.UpdatePostRequest{
			Title: &newTitle,
		}

		existingPost := &models.Post{
			ID:       1,
			AuthorID: 1, // Original author
		}

		user := &models.User{
			ID:   2,
			Role: "author", // Not admin
		}

		// Mock expectations
		mockPostRepo.On("GetByID", postID).Return(existingPost, nil).Once()
		mockUserRepo.On("GetByID", userID).Return(user, nil).Once()

		// When
		result, err := postService.UpdatePost(userID, postID, updatePostData)

		// Then
		assert.Error(t, err)
		assert.Nil(t, result)
		assert.Equal(t, "access denied", err.Error())

		mockPostRepo.AssertExpectations(t)
		mockUserRepo.AssertExpectations(t)
	})

	t.Run("admin can update any post", func(t *testing.T) {
		// Given
		postID := uint(1)
		userID := uint(2)
		newTitle := "Updated Test Post"
		updatePostData := &models.UpdatePostRequest{
			Title: &newTitle,
		}

		existingPost := &models.Post{
			ID:       1,
			AuthorID: 1, // Different author
		}

		adminUser := &models.User{
			ID:   2,
			Role: "admin", // Admin can update any post
		}

		// Mock expectations
		mockPostRepo.On("GetByID", postID).Return(existingPost, nil).Once()
		mockUserRepo.On("GetByID", userID).Return(adminUser, nil).Once()
		mockPostRepo.On("Update", mock.AnythingOfType("*models.Post")).Return(nil).Once()

		// When
		result, err := postService.UpdatePost(userID, postID, updatePostData)

		// Then
		require.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, "Updated Test Post", result.Title)

		mockPostRepo.AssertExpectations(t)
		mockUserRepo.AssertExpectations(t)
	})
}

func TestPostService_Integration(t *testing.T) {
	// Setup test database
	db := testutils.MockDatabase(t)

	// Create real repositories
	postRepo := NewPostRepository(db)
	userRepo := NewUserRepository(db)
	categoryRepo := NewCategoryRepository(db)

	// Create real service
	postService := NewPostService(postRepo, userRepo, categoryRepo)

	t.Run("full post lifecycle", func(t *testing.T) {
		// Create test user
		user := &models.User{
			Username: "testauthor",
			Name:     "Test Author",
			Email:    "author@test.com",
			Password: "$2a$12$hash",
			Role:     "author",
		}
		err := userRepo.Create(user)
		require.NoError(t, err)

		// Create test category
		category := &models.Category{
			Name: "Test Category",
			Slug: "test-category",
		}
		err = categoryRepo.Create(category)
		require.NoError(t, err)

		// Create post
		createPostData := &models.CreatePostRequest{
			Title:      "Integration Test Post",
			Content:    "This is a comprehensive integration test post content that meets all validation requirements.",
			Excerpt:    "Integration test excerpt",
			CategoryID: category.ID,
			Status:     "draft",
		}

		createdPost, err := postService.CreatePost(user.ID, createPostData)
		require.NoError(t, err)
		assert.NotNil(t, createdPost)
		assert.Equal(t, "Integration Test Post", createdPost.Title)
		assert.Equal(t, "integration-test-post", createdPost.Slug)

		// Get post by ID
		retrievedPost, err := postService.GetPostByID(createdPost.ID)
		require.NoError(t, err)
		assert.Equal(t, createdPost.ID, retrievedPost.ID)
		assert.Equal(t, createdPost.Title, retrievedPost.Title)

		// Update post
		newTitle := "Updated Integration Test Post"
		updatePostData := &models.UpdatePostRequest{
			Title: &newTitle,
		}

		updatedPost, err := postService.UpdatePost(user.ID, createdPost.ID, updatePostData)
		require.NoError(t, err)
		assert.Equal(t, "Updated Integration Test Post", updatedPost.Title)

		// Delete post
		err = postService.DeletePost(user.ID, createdPost.ID)
		require.NoError(t, err)

		// Verify post is deleted
		_, err = postService.GetPostByID(createdPost.ID)
		assert.Error(t, err)
		assert.Equal(t, "post not found", err.Error())
	})
}
