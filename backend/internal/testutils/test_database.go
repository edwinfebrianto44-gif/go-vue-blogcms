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
	"gorm.io/gorm"
)

// TestDatabase holds test database configuration
type TestDatabase struct {
	Container testcontainers.Container
	DB        *gorm.DB
	DSN       string
}

// SetupTestDatabase creates a MySQL test container and connects to it
func SetupTestDatabase(t *testing.T) *TestDatabase {
	ctx := context.Background()

	// Start MySQL container
	mysqlContainer, err := mysql.RunContainer(ctx,
		testcontainers.WithImage("mysql:8.0"),
		mysql.WithDatabase("test_blogcms"),
		mysql.WithUsername("test"),
		mysql.WithPassword("test123"),
		testcontainers.WithWaitStrategy(
			testcontainers.NewLogStrategy("port: 3306").
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

	// Close database connection
	sqlDB, err := td.DB.DB()
	if err == nil {
		sqlDB.Close()
	}

	// Terminate container
	err = td.Container.Terminate(ctx)
	require.NoError(t, err)
}

// CleanDatabase truncates all tables for clean test state
func (td *TestDatabase) CleanDatabase(t *testing.T) {
	// Get underlying sql.DB
	sqlDB, err := td.DB.DB()
	require.NoError(t, err)

	// Disable foreign key checks
	_, err = sqlDB.Exec("SET FOREIGN_KEY_CHECKS = 0")
	require.NoError(t, err)

	// Get all table names
	rows, err := sqlDB.Query("SHOW TABLES")
	require.NoError(t, err)
	defer rows.Close()

	var tables []string
	for rows.Next() {
		var tableName string
		err := rows.Scan(&tableName)
		require.NoError(t, err)
		tables = append(tables, tableName)
	}

	// Truncate all tables
	for _, table := range tables {
		_, err = sqlDB.Exec(fmt.Sprintf("TRUNCATE TABLE %s", table))
		require.NoError(t, err)
	}

	// Re-enable foreign key checks
	_, err = sqlDB.Exec("SET FOREIGN_KEY_CHECKS = 1")
	require.NoError(t, err)
}

// SeedTestData creates test data for integration tests
func (td *TestDatabase) SeedTestData(t *testing.T) *TestData {
	// Create test users
	admin := &models.User{
		Name:     "Admin User",
		Email:    "admin@test.com",
		Role:     "admin",
		Password: "$2a$12$hash", // Hashed password for "password123"
	}
	err := td.DB.Create(admin).Error
	require.NoError(t, err)

	author := &models.User{
		Name:     "Author User",
		Email:    "author@test.com",
		Role:     "author",
		Password: "$2a$12$hash", // Hashed password for "password123"
	}
	err = td.DB.Create(author).Error
	require.NoError(t, err)

	// Create test category
	category := &models.Category{
		Name:        "Test Category",
		Slug:        "test-category",
		Description: "Test category description",
	}
	err = td.DB.Create(category).Error
	require.NoError(t, err)

	// Create test posts
	publishedPost := &models.Post{
		Title:      "Published Test Post",
		Slug:       "published-test-post",
		Content:    "This is a published test post content",
		Excerpt:    "Published test excerpt",
		Status:     "published",
		AuthorID:   author.ID,
		CategoryID: category.ID,
	}
	err = td.DB.Create(publishedPost).Error
	require.NoError(t, err)

	draftPost := &models.Post{
		Title:      "Draft Test Post",
		Slug:       "draft-test-post",
		Content:    "This is a draft test post content",
		Excerpt:    "Draft test excerpt",
		Status:     "draft",
		AuthorID:   author.ID,
		CategoryID: category.ID,
	}
	err = td.DB.Create(draftPost).Error
	require.NoError(t, err)

	// Create test comments
	comment := &models.Comment{
		PostID:  publishedPost.ID,
		UserID:  admin.ID,
		Content: "This is a test comment",
		Status:  "approved",
	}
	err = td.DB.Create(comment).Error
	require.NoError(t, err)

	return &TestData{
		Admin:         admin,
		Author:        author,
		Category:      category,
		PublishedPost: publishedPost,
		DraftPost:     draftPost,
		Comment:       comment,
	}
}

// TestData holds seeded test data
type TestData struct {
	Admin         *models.User
	Author        *models.User
	Category      *models.Category
	PublishedPost *models.Post
	DraftPost     *models.Post
	Comment       *models.Comment
}

// GetTestDSN returns a test database DSN for unit tests (without container)
func GetTestDSN() string {
	return "test:test123@tcp(localhost:3306)/test_blogcms?charset=utf8mb4&parseTime=True&loc=Local&multiStatements=true"
}

// MockDatabase creates an in-memory database for unit tests
func MockDatabase(t *testing.T) *gorm.DB {
	// For unit tests, we'll use SQLite in-memory database
	db, err := database.ConnectSQLite(":memory:")
	require.NoError(t, err)

	// Run migrations
	err = database.AutoMigrate(db)
	require.NoError(t, err)

	return db
}
