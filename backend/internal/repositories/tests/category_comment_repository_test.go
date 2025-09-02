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

func TestCategoryRepository(t *testing.T) {
	testDB := testutils.SetupTestDatabase(t)
	defer testDB.TeardownTestDatabase(t)

	categoryRepo := repositories.NewCategoryRepository(testDB.DB)

	t.Run("Create Category", func(t *testing.T) {
		category := &models.Category{
			Name:        "Technology",
			Slug:        "technology",
			Description: "Articles about technology and programming",
		}

		err := categoryRepo.Create(category)
		require.NoError(t, err)
		assert.NotZero(t, category.ID)
		assert.NotZero(t, category.CreatedAt)
		assert.NotZero(t, category.UpdatedAt)
	})

	t.Run("GetByID", func(t *testing.T) {
		// Create test category
		category := &models.Category{
			Name:        "Science",
			Slug:        "science",
			Description: "Scientific articles and research",
		}
		err := categoryRepo.Create(category)
		require.NoError(t, err)

		// Get by ID
		retrieved, err := categoryRepo.GetByID(category.ID)
		require.NoError(t, err)
		assert.Equal(t, category.Name, retrieved.Name)
		assert.Equal(t, category.Slug, retrieved.Slug)
		assert.Equal(t, category.Description, retrieved.Description)
	})

	t.Run("GetBySlug", func(t *testing.T) {
		// Create test category
		category := &models.Category{
			Name:        "Health",
			Slug:        "health",
			Description: "Health and wellness articles",
		}
		err := categoryRepo.Create(category)
		require.NoError(t, err)

		// Get by slug
		retrieved, err := categoryRepo.GetBySlug(category.Slug)
		require.NoError(t, err)
		assert.Equal(t, category.Name, retrieved.Name)
		assert.Equal(t, category.ID, retrieved.ID)
	})

	t.Run("List All Categories", func(t *testing.T) {
		// Create multiple test categories
		categories := []models.Category{
			{Name: "Sports", Slug: "sports", Description: "Sports news and updates"},
			{Name: "Entertainment", Slug: "entertainment", Description: "Entertainment and media"},
			{Name: "Finance", Slug: "finance", Description: "Financial news and advice"},
		}

		for i := range categories {
			err := categoryRepo.Create(&categories[i])
			require.NoError(t, err)
		}

		// Get all categories
		allCategories, total, err := categoryRepo.List(1, 100)
		require.NoError(t, err)
		assert.GreaterOrEqual(t, len(allCategories), 3)
		assert.GreaterOrEqual(t, total, int64(3))
	})

	t.Run("Update Category", func(t *testing.T) {
		// Create test category
		category := &models.Category{
			Name:        "Original Name",
			Slug:        "original-name",
			Description: "Original description",
		}
		err := categoryRepo.Create(category)
		require.NoError(t, err)

		// Update category
		category.Name = "Updated Name"
		category.Description = "Updated description"
		err = categoryRepo.Update(category)
		require.NoError(t, err)

		// Verify update
		retrieved, err := categoryRepo.GetByID(category.ID)
		require.NoError(t, err)
		assert.Equal(t, "Updated Name", retrieved.Name)
		assert.Equal(t, "Updated description", retrieved.Description)
	})

	t.Run("Delete Category", func(t *testing.T) {
		// Create test category
		category := &models.Category{
			Name:        "To Be Deleted",
			Slug:        "to-be-deleted",
			Description: "This category will be deleted",
		}
		err := categoryRepo.Create(category)
		require.NoError(t, err)

		// Delete category
		err = categoryRepo.Delete(category.ID)
		require.NoError(t, err)

		// Verify deletion
		_, err = categoryRepo.GetByID(category.ID)
		assert.Error(t, err)
	})
}

func TestCommentRepository(t *testing.T) {
	testDB := testutils.SetupTestDatabase(t)
	defer testDB.TeardownTestDatabase(t)
	testData := testDB.SeedTestData(t)

	commentRepo := repositories.NewCommentRepository(testDB.DB)

	t.Run("Create Comment", func(t *testing.T) {
		comment := &models.Comment{
			PostID:  testData.PublishedPost.ID,
			UserID:  testData.Author.ID,
			Content: "This is a test comment",
			Status:  "approved",
		}

		err := commentRepo.Create(comment)
		require.NoError(t, err)
		assert.NotZero(t, comment.ID)
		assert.NotZero(t, comment.CreatedAt)
		assert.NotZero(t, comment.UpdatedAt)
	})

	t.Run("GetByID", func(t *testing.T) {
		// Create test comment
		comment := &models.Comment{
			PostID:  testData.PublishedPost.ID,
			UserID:  testData.Author.ID,
			Content: "Another test comment",
			Status:  "approved",
		}
		err := commentRepo.Create(comment)
		require.NoError(t, err)

		// Get by ID
		retrieved, err := commentRepo.GetByID(comment.ID)
		require.NoError(t, err)
		assert.Equal(t, comment.Content, retrieved.Content)
		assert.Equal(t, comment.PostID, retrieved.PostID)
		assert.Equal(t, comment.UserID, retrieved.UserID)
	})

	t.Run("GetByPost", func(t *testing.T) {
		// Create multiple comments for a post
		for i := 0; i < 3; i++ {
			comment := &models.Comment{
				PostID:  testData.PublishedPost.ID,
				UserID:  testData.Author.ID,
				Content: fmt.Sprintf("Comment number %d", i+1),
				Status:  "approved",
			}
			err := commentRepo.Create(comment)
			require.NoError(t, err)
		}

		// Get comments for the post
		comments, total, err := commentRepo.GetByPost(testData.PublishedPost.ID, 1, 10)
		require.NoError(t, err)
		assert.GreaterOrEqual(t, len(comments), 3)
		assert.GreaterOrEqual(t, total, int64(3))

		// Verify all comments belong to the post
		for _, comment := range comments {
			assert.Equal(t, testData.PublishedPost.ID, comment.PostID)
		}
	})

	t.Run("GetByUser", func(t *testing.T) {
		// Create comment by specific author
		comment := &models.Comment{
			PostID:  testData.PublishedPost.ID,
			UserID:  testData.Author.ID,
			Content: "Comment by specific author",
			Status:  "approved",
		}
		err := commentRepo.Create(comment)
		require.NoError(t, err)

		// Get comments by author
		comments, total, err := commentRepo.GetByUser(testData.Author.ID, 1, 10)
		require.NoError(t, err)
		assert.GreaterOrEqual(t, len(comments), 1)
		assert.GreaterOrEqual(t, total, int64(1))

		// Verify all comments belong to the author
		for _, comment := range comments {
			assert.Equal(t, testData.Author.ID, comment.UserID)
		}
	})

	t.Run("List Comments with Filters", func(t *testing.T) {
		// Create approved and pending comments
		approvedComment := &models.Comment{
			PostID:  testData.PublishedPost.ID,
			UserID:  testData.Author.ID,
			Content: "Approved comment",
			Status:  "approved",
		}
		err := commentRepo.Create(approvedComment)
		require.NoError(t, err)

		pendingComment := &models.Comment{
			PostID:  testData.PublishedPost.ID,
			UserID:  testData.Author.ID,
			Content: "Pending comment",
			Status:  "pending",
		}
		err = commentRepo.Create(pendingComment)
		require.NoError(t, err)

		// Get approved comments using filters
		filters := map[string]interface{}{
			"status": "approved",
		}
		comments, total, err := commentRepo.List(1, 10, filters)
		require.NoError(t, err)

		// Verify all comments are approved
		for _, comment := range comments {
			assert.Equal(t, "approved", comment.Status)
		}
		assert.GreaterOrEqual(t, total, int64(1))
	})

	t.Run("Update Comment", func(t *testing.T) {
		// Create test comment
		comment := &models.Comment{
			PostID:  testData.PublishedPost.ID,
			UserID:  testData.Author.ID,
			Content: "Original comment content",
			Status:  "pending",
		}
		err := commentRepo.Create(comment)
		require.NoError(t, err)

		// Update comment
		comment.Content = "Updated comment content"
		comment.Status = "approved"
		err = commentRepo.Update(comment)
		require.NoError(t, err)

		// Verify update
		retrieved, err := commentRepo.GetByID(comment.ID)
		require.NoError(t, err)
		assert.Equal(t, "Updated comment content", retrieved.Content)
		assert.Equal(t, "approved", retrieved.Status)
	})

	t.Run("Delete Comment", func(t *testing.T) {
		// Create test comment
		comment := &models.Comment{
			PostID:  testData.PublishedPost.ID,
			UserID:  testData.Author.ID,
			Content: "Comment to be deleted",
			Status:  "approved",
		}
		err := commentRepo.Create(comment)
		require.NoError(t, err)

		// Delete comment
		err = commentRepo.Delete(comment.ID)
		require.NoError(t, err)

		// Verify deletion
		_, err = commentRepo.GetByID(comment.ID)
		assert.Error(t, err)
	})

	t.Run("Change Comment Status", func(t *testing.T) {
		// Create pending comment
		comment := &models.Comment{
			PostID:  testData.PublishedPost.ID,
			UserID:  testData.Author.ID,
			Content: "Comment to be approved",
			Status:  "pending",
		}
		err := commentRepo.Create(comment)
		require.NoError(t, err)

		// Approve comment by updating status
		comment.Status = "approved"
		err = commentRepo.Update(comment)
		require.NoError(t, err)

		// Verify approval
		retrieved, err := commentRepo.GetByID(comment.ID)
		require.NoError(t, err)
		assert.Equal(t, "approved", retrieved.Status)
	})

	t.Run("Reject Comment", func(t *testing.T) {
		// Create pending comment
		comment := &models.Comment{
			PostID:  testData.PublishedPost.ID,
			UserID:  testData.Author.ID,
			Content: "Comment to be rejected",
			Status:  "pending",
		}
		err := commentRepo.Create(comment)
		require.NoError(t, err)

		// Reject comment by updating status
		comment.Status = "rejected"
		err = commentRepo.Update(comment)
		require.NoError(t, err)

		// Verify rejection
		retrieved, err := commentRepo.GetByID(comment.ID)
		require.NoError(t, err)
		assert.Equal(t, "rejected", retrieved.Status)
	})
}
