package tests

import (
	"fmt"
	"testing"

	"backend/internal/models"
	"backend/internal/repositories"
	"backend/internal/testutils"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestUserRepository(t *testing.T) {
	testDB := testutils.SetupTestDatabase(t)
	defer testDB.TeardownTestDatabase(t)

	userRepo := repositories.NewUserRepository(testDB.DB)

	t.Run("Create User", func(t *testing.T) {
		user := &models.User{
			Username: "testuser",
			Name:     "Test User",
			Email:    "testuser@example.com",
			Password: "hashed_password",
			Role:     "author",
		}

		err := userRepo.Create(user)
		require.NoError(t, err)
		assert.NotZero(t, user.ID)
		assert.NotZero(t, user.CreatedAt)
		assert.NotZero(t, user.UpdatedAt)
	})

	t.Run("GetByID", func(t *testing.T) {
		// Create test user
		user := &models.User{
			Username: "testuser2",
			Name:     "Test User 2",
			Email:    "testuser2@example.com",
			Password: "hashed_password",
			Role:     "author",
		}
		err := userRepo.Create(user)
		require.NoError(t, err)

		// Get by ID
		retrieved, err := userRepo.GetByID(user.ID)
		require.NoError(t, err)
		assert.Equal(t, user.Username, retrieved.Username)
		assert.Equal(t, user.Email, retrieved.Email)
	})

	t.Run("GetByEmail", func(t *testing.T) {
		// Create test user
		user := &models.User{
			Username: "testuser3",
			Name:     "Test User 3",
			Email:    "testuser3@example.com",
			Password: "hashed_password",
			Role:     "author",
		}
		err := userRepo.Create(user)
		require.NoError(t, err)

		// Get by email
		retrieved, err := userRepo.GetByEmail(user.Email)
		require.NoError(t, err)
		assert.Equal(t, user.Username, retrieved.Username)
		assert.Equal(t, user.ID, retrieved.ID)
	})

	t.Run("GetByUsername", func(t *testing.T) {
		// Create test user
		user := &models.User{
			Username: "testuser4",
			Name:     "Test User 4",
			Email:    "testuser4@example.com",
			Password: "hashed_password",
			Role:     "author",
		}
		err := userRepo.Create(user)
		require.NoError(t, err)

		// Get by username
		retrieved, err := userRepo.GetByUsername(user.Username)
		require.NoError(t, err)
		assert.Equal(t, user.Email, retrieved.Email)
		assert.Equal(t, user.ID, retrieved.ID)
	})

	t.Run("Update User", func(t *testing.T) {
		// Create test user
		user := &models.User{
			Username: "testuser5",
			Name:     "Test User 5",
			Email:    "testuser5@example.com",
			Password: "hashed_password",
			Role:     "author",
		}
		err := userRepo.Create(user)
		require.NoError(t, err)

		// Update user
		user.Name = "Updated Name"
		err = userRepo.Update(user)
		require.NoError(t, err)

		// Verify update
		retrieved, err := userRepo.GetByID(user.ID)
		require.NoError(t, err)
		assert.Equal(t, "Updated Name", retrieved.Name)
	})

	t.Run("Delete User", func(t *testing.T) {
		// Create test user
		user := &models.User{
			Username: "testuser6",
			Name:     "Test User 6",
			Email:    "testuser6@example.com",
			Password: "hashed_password",
			Role:     "author",
		}
		err := userRepo.Create(user)
		require.NoError(t, err)

		// Delete user
		err = userRepo.Delete(user.ID)
		require.NoError(t, err)

		// Verify deletion
		_, err = userRepo.GetByID(user.ID)
		assert.Error(t, err)
	})

	t.Run("GetAll Users", func(t *testing.T) {
		// Create multiple test users
		for i := 0; i < 3; i++ {
			user := &models.User{
				Username: fmt.Sprintf("bulkuser%d", i),
				Name:     fmt.Sprintf("Bulk User %d", i),
				Email:    fmt.Sprintf("bulkuser%d@example.com", i),
				Password: "hashed_password",
				Role:     "author",
			}
			err := userRepo.Create(user)
			require.NoError(t, err)
		}

		// Get all users - using List method instead of GetAll
		users, total, err := userRepo.List(1, 100)
		require.NoError(t, err)
		assert.GreaterOrEqual(t, len(users), 3)
		assert.GreaterOrEqual(t, total, int64(3))
	})
}

func TestPostRepository(t *testing.T) {
	testDB := testutils.SetupTestDatabase(t)
	defer testDB.TeardownTestDatabase(t)
	testData := testDB.SeedTestData(t)

	postRepo := repositories.NewPostRepository(testDB.DB)

	t.Run("Create Post", func(t *testing.T) {
		post := &models.Post{
			Title:      "Test Post",
			Slug:       "test-post",
			Content:    "This is test content",
			Excerpt:    "Test excerpt",
			AuthorID:   testData.Author.ID,
			CategoryID: testData.Category.ID,
			Status:     "draft",
		}

		err := postRepo.Create(post)
		require.NoError(t, err)
		assert.NotZero(t, post.ID)
		assert.NotZero(t, post.CreatedAt)
		assert.NotZero(t, post.UpdatedAt)
	})

	t.Run("GetByID", func(t *testing.T) {
		// Create test post
		post := &models.Post{
			Title:      "Test Post 2",
			Slug:       "test-post-2",
			Content:    "This is test content 2",
			Excerpt:    "Test summary 2",
			AuthorID:   testData.Author.ID,
			CategoryID: testData.Category.ID,
			Status:     "published",
		}
		err := postRepo.Create(post)
		require.NoError(t, err)

		// Get by ID
		retrieved, err := postRepo.GetByID(post.ID)
		require.NoError(t, err)
		assert.Equal(t, post.Title, retrieved.Title)
		assert.Equal(t, post.Slug, retrieved.Slug)
		assert.Equal(t, post.Status, retrieved.Status)
	})

	t.Run("GetBySlug", func(t *testing.T) {
		// Create test post
		post := &models.Post{
			Title:      "Test Post 3",
			Slug:       "test-post-3",
			Content:    "This is test content 3",
			Excerpt:    "Test summary 3",
			AuthorID:   testData.Author.ID,
			CategoryID: testData.Category.ID,
			Status:     "published",
		}
		err := postRepo.Create(post)
		require.NoError(t, err)

		// Get by slug
		retrieved, err := postRepo.GetBySlug(post.Slug)
		require.NoError(t, err)
		assert.Equal(t, post.Title, retrieved.Title)
		assert.Equal(t, post.ID, retrieved.ID)
	})

	t.Run("GetPublished", func(t *testing.T) {
		// Create published and draft posts
		publishedPost := &models.Post{
			Title:      "Published Post",
			Slug:       "published-post",
			Content:    "Published content",
			Excerpt:    "Published summary",
			AuthorID:   testData.Author.ID,
			CategoryID: testData.Category.ID,
			Status:     "published",
		}
		err := postRepo.Create(publishedPost)
		require.NoError(t, err)

		draftPost := &models.Post{
			Title:      "Draft Post",
			Slug:       "draft-post",
			Content:    "Draft content",
			Excerpt:    "Draft summary",
			AuthorID:   testData.Author.ID,
			CategoryID: testData.Category.ID,
			Status:     "draft",
		}
		err = postRepo.Create(draftPost)
		require.NoError(t, err)

		// Get published posts
		posts, err := postRepo.GetPublished(10, 0)
		require.NoError(t, err)

		// Check that only published posts are returned
		for _, post := range posts {
			assert.Equal(t, "published", post.Status)
		}
	})

	t.Run("GetByAuthorID", func(t *testing.T) {
		// Get posts by author
		posts, err := postRepo.GetByAuthorID(testData.Author.ID, 10, 0)
		require.NoError(t, err)

		// Verify all posts belong to the author
		for _, post := range posts {
			assert.Equal(t, testData.Author.ID, post.AuthorID)
		}
	})

	t.Run("GetByCategoryID", func(t *testing.T) {
		// Get posts by category
		posts, err := postRepo.GetByCategoryID(testData.Category.ID, 10, 0)
		require.NoError(t, err)

		// Verify all posts belong to the category
		for _, post := range posts {
			assert.Equal(t, testData.Category.ID, post.CategoryID)
		}
	})

	t.Run("Update Post", func(t *testing.T) {
		// Create test post
		post := &models.Post{
			Title:      "Update Test Post",
			Slug:       "update-test-post",
			Content:    "Original content",
			Excerpt:    "Original summary",
			AuthorID:   testData.Author.ID,
			CategoryID: testData.Category.ID,
			Status:     "draft",
		}
		err := postRepo.Create(post)
		require.NoError(t, err)

		// Update post
		post.Title = "Updated Post Title"
		post.Content = "Updated content"
		post.Status = "published"
		err = postRepo.Update(post)
		require.NoError(t, err)

		// Verify update
		retrieved, err := postRepo.GetByID(post.ID)
		require.NoError(t, err)
		assert.Equal(t, "Updated Post Title", retrieved.Title)
		assert.Equal(t, "Updated content", retrieved.Content)
		assert.Equal(t, "published", retrieved.Status)
	})

	t.Run("Delete Post", func(t *testing.T) {
		// Create test post
		post := &models.Post{
			Title:      "Delete Test Post",
			Slug:       "delete-test-post",
			Content:    "Content to be deleted",
			Excerpt:    "Summary to be deleted",
			AuthorID:   testData.Author.ID,
			CategoryID: testData.Category.ID,
			Status:     "draft",
		}
		err := postRepo.Create(post)
		require.NoError(t, err)

		// Delete post
		err = postRepo.Delete(post.ID)
		require.NoError(t, err)

		// Verify deletion
		_, err = postRepo.GetByID(post.ID)
		assert.Error(t, err)
	})

	t.Run("Search Posts", func(t *testing.T) {
		// Create searchable posts
		searchPost := &models.Post{
			Title:      "Searchable Post About Technology",
			Slug:       "searchable-tech-post",
			Content:    "This post discusses various technology trends and innovations",
			Excerpt:    "Technology trends summary",
			AuthorID:   testData.Author.ID,
			CategoryID: testData.Category.ID,
			Status:     "published",
		}
		err := postRepo.Create(searchPost)
		require.NoError(t, err)

		// Search for posts
		posts, err := postRepo.Search("technology", 10, 0)
		require.NoError(t, err)

		// Should find at least one post
		assert.GreaterOrEqual(t, len(posts), 1)

		// Check that found posts contain the search term
		found := false
		for _, post := range posts {
			if post.ID == searchPost.ID {
				found = true
				break
			}
		}
		assert.True(t, found)
	})
}
