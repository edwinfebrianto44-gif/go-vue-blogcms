package testutils

import (
	"context"
	"fmt"
	"testing"
	"time"

	"backend/internal/database"
	"backend/internal/models"

	"github.com/stretchr/testify/require"
	"github.com/testcontainers/testcontainers-go"
	"github.com/testcontainers/testcontainers-go/modules/mysql"
	"github.com/testcontainers/testcontainers-go/wait"
	"gorm.io/gorm"
)

// TestDatabase holds test database configuration
type TestDatabase struct {
	Container testcontainers.Container
	DB        *gorm.DB
	DSN       string
}

// SetupTestDatabase creates a test database using testcontainers
func SetupTestDatabase(t *testing.T) *TestDatabase {
	ctx := context.Background()

	// Start MySQL container
	mysqlContainer, err := mysql.RunContainer(ctx,
		testcontainers.WithImage("mysql:8.0"),
		mysql.WithDatabase("test_blogcms"),
		mysql.WithUsername("test"),
		mysql.WithPassword("test123"),
		testcontainers.WithWaitStrategy(
			wait.ForLog("port: 3306").
				WithStartupTimeout(60*time.Second),
		),
	)
	require.NoError(t, err)

	// Get connection string
	connStr, err := mysqlContainer.ConnectionString(ctx, "multiStatements=true&parseTime=true")
	require.NoError(t, err)

	// Connect to database
	db, err := database.Connect(connStr)
	require.NoError(t, err)

	// Run migrations
	err = database.AutoMigrate(db)
	require.NoError(t, err)

	return &TestDatabase{
		Container: mysqlContainer,
		DB:        db,
		DSN:       connStr,
	}
}

// TeardownTestDatabase cleans up the test database
func (td *TestDatabase) TeardownTestDatabase(t *testing.T) {
	ctx := context.Background()
	if td.Container != nil {
		err := td.Container.Terminate(ctx)
		require.NoError(t, err)
	}
}

// CleanDatabase truncates all tables for a clean state
func (td *TestDatabase) CleanDatabase(t *testing.T) {
	// Disable foreign key checks
	td.DB.Exec("SET FOREIGN_KEY_CHECKS = 0")

	// Get all table names
	var tables []string
	td.DB.Raw("SHOW TABLES").Scan(&tables)

	// Truncate each table
	for _, table := range tables {
		td.DB.Exec(fmt.Sprintf("TRUNCATE TABLE %s", table))
	}

	// Re-enable foreign key checks
	td.DB.Exec("SET FOREIGN_KEY_CHECKS = 1")
}

// SeedTestData creates test data for testing
func (td *TestDatabase) SeedTestData(t *testing.T) *TestData {
	// Create test user
	author := &models.User{
		Username:     "testauthor",
		Name:         "Test Author",
		Email:        "author@test.com",
		PasswordHash: "hashed_password",
		Role:         "author",
		Bio:          "Test author bio",
		Avatar:       "test_avatar.jpg",
	}
	result := td.DB.Create(author)
	require.NoError(t, result.Error)

	// Create test admin
	admin := &models.User{
		Username:     "testadmin",
		Name:         "Test Admin",
		Email:        "admin@test.com",
		PasswordHash: "hashed_password",
		Role:         "admin",
		Bio:          "Test admin bio",
		Avatar:       "admin_avatar.jpg",
	}
	result = td.DB.Create(admin)
	require.NoError(t, result.Error)

	// Create test category
	category := &models.Category{
		Name:        "Test Category",
		Slug:        "test-category",
		Description: "Test category description",
	}
	result = td.DB.Create(category)
	require.NoError(t, result.Error)

	// Create published post
	publishedPost := &models.Post{
		Title:      "Published Test Post",
		Slug:       "published-test-post",
		Content:    "This is a published test post content",
		Summary:    "Published test post summary",
		AuthorID:   author.ID,
		CategoryID: category.ID,
		Status:     "published",
		Tags:       "test,published",
	}
	result = td.DB.Create(publishedPost)
	require.NoError(t, result.Error)

	// Create draft post
	draftPost := &models.Post{
		Title:      "Draft Test Post",
		Slug:       "draft-test-post",
		Content:    "This is a draft test post content",
		Summary:    "Draft test post summary",
		AuthorID:   author.ID,
		CategoryID: category.ID,
		Status:     "draft",
		Tags:       "test,draft",
	}
	result = td.DB.Create(draftPost)
	require.NoError(t, result.Error)

	// Create test comment
	comment := &models.Comment{
		PostID:   publishedPost.ID,
		AuthorID: author.ID,
		Content:  "This is a test comment",
		Status:   "approved",
	}
	result = td.DB.Create(comment)
	require.NoError(t, result.Error)

	return &TestData{
		Author:        author,
		Admin:         admin,
		Category:      category,
		PublishedPost: publishedPost,
		DraftPost:     draftPost,
		Comment:       comment,
	}
}

// TestData holds references to created test data
type TestData struct {
	Author        *models.User
	Admin         *models.User
	Category      *models.Category
	PublishedPost *models.Post
	DraftPost     *models.Post
	Comment       *models.Comment
}

// GetTestDSN returns a test DSN for SQLite
func GetTestDSN() string {
	return ":memory:"
}

// MockDatabase creates an in-memory SQLite database for testing
func MockDatabase(t *testing.T) *gorm.DB {
	db, err := database.ConnectSQLite(GetTestDSN())
	require.NoError(t, err)

	// Run migrations
	err = database.AutoMigrate(db)
	require.NoError(t, err)

	return db
}
