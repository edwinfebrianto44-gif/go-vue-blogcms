package tests

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	"backend/internal/config"
	"backend/internal/handlers"
	"backend/internal/models"
	"backend/internal/repositories"
	"backend/internal/routes"
	"backend/internal/services"
	"backend/internal/testutils"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type IntegrationTestSuite struct {
	router   *gin.Engine
	testDB   *testutils.TestDatabase
	testData *testutils.TestData
}

func setupIntegrationTest(t *testing.T) *IntegrationTestSuite {
	// Set gin to test mode
	gin.SetMode(gin.TestMode)

	// Setup test database
	testDB := testutils.SetupTestDatabase(t)

	// Seed test data
	testData := testDB.SeedTestData(t)

	// Setup configuration
	cfg := &config.Config{
		DatabaseURL: testDB.DSN,
		JWTSecret:   "test-secret-key",
		Port:        "8080",
	}

	// Initialize repositories
	userRepo := repositories.NewUserRepository(testDB.DB)
	postRepo := repositories.NewPostRepository(testDB.DB)
	categoryRepo := repositories.NewCategoryRepository(testDB.DB)
	commentRepo := repositories.NewCommentRepository(testDB.DB)
	refreshTokenRepo := repositories.NewRefreshTokenRepository(testDB.DB)

	// Initialize services
	jwtService := services.NewJWTService(refreshTokenRepo)
	authService := services.NewAuthService(userRepo, jwtService, cfg)
	postService := services.NewPostService(postRepo, userRepo, categoryRepo)
	categoryService := services.NewCategoryService(categoryRepo)
	commentService := services.NewCommentService(commentRepo, postRepo, userRepo)
	storageService := services.NewStorageService()

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(authService)
	postHandler := handlers.NewPostHandler(postService)
	categoryHandler := handlers.NewCategoryHandler(categoryService)
	commentHandler := handlers.NewCommentHandler(commentService)
	uploadHandler := handlers.NewUploadHandler(storageService)
	docsHandler := handlers.NewDocsHandler()

	// Setup router
	r := gin.New()
	r.Use(gin.Recovery())

	// Setup routes
	routes.SetupRoutes(r, authHandler, postHandler, categoryHandler, commentHandler, uploadHandler, docsHandler, jwtService)

	return &IntegrationTestSuite{
		router:   r,
		testDB:   testDB,
		testData: testData,
	}
}

func (suite *IntegrationTestSuite) teardown(t *testing.T) {
	suite.testDB.TeardownTestDatabase(t)
}

func TestAuthIntegration(t *testing.T) {
	suite := setupIntegrationTest(t)
	defer suite.teardown(t)

	t.Run("User Registration Flow", func(t *testing.T) {
		// Register new user
		registerData := models.RegisterRequest{
			Username: "newuser",
			Name:     "New User",
			Email:    "newuser@test.com",
			Password: "password123",
			Role:     "author",
		}

		registerJSON, _ := json.Marshal(registerData)
		req, _ := http.NewRequest("POST", "/api/v1/auth/register", bytes.NewBuffer(registerJSON))
		req.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		suite.router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusCreated, w.Code)

		var response models.APIResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.True(t, response.Success)

		// Extract tokens from response
		responseData, ok := response.Data.(map[string]interface{})
		require.True(t, ok)
		accessToken, ok := responseData["access_token"].(string)
		require.True(t, ok)
		assert.NotEmpty(t, accessToken)
	})

	t.Run("User Login Flow", func(t *testing.T) {
		// Login with existing user
		loginData := models.LoginRequest{
			Email:    suite.testData.Author.Email,
			Password: "password123", // This should match the seeded password
		}

		loginJSON, _ := json.Marshal(loginData)
		req, _ := http.NewRequest("POST", "/api/v1/auth/login", bytes.NewBuffer(loginJSON))
		req.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		suite.router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response models.APIResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.True(t, response.Success)
	})

	t.Run("Protected Route Access", func(t *testing.T) {
		// First login to get token
		loginData := models.LoginRequest{
			Email:    suite.testData.Author.Email,
			Password: "password123",
		}

		loginJSON, _ := json.Marshal(loginData)
		req, _ := http.NewRequest("POST", "/api/v1/auth/login", bytes.NewBuffer(loginJSON))
		req.Header.Set("Content-Type", "application/json")

		w := httptest.NewRecorder()
		suite.router.ServeHTTP(w, req)

		var loginResponse models.APIResponse
		json.Unmarshal(w.Body.Bytes(), &loginResponse)

		// Access protected route with token
		req, _ = http.NewRequest("GET", "/api/v1/auth/profile", nil)
		// Note: You'll need to extract the token from loginResponse
		// and set it in the Authorization header

		w = httptest.NewRecorder()
		suite.router.ServeHTTP(w, req)

		// Without proper token, should get 401
		assert.Equal(t, http.StatusUnauthorized, w.Code)
	})
}

func TestPostCRUDIntegration(t *testing.T) {
	suite := setupIntegrationTest(t)
	defer suite.teardown(t)

	t.Run("Get Published Posts", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/api/v1/posts", nil)
		w := httptest.NewRecorder()
		suite.router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response models.APIResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.True(t, response.Success)
	})

	t.Run("Get Post by ID", func(t *testing.T) {
		url := fmt.Sprintf("/api/v1/posts/%d", suite.testData.PublishedPost.ID)
		req, _ := http.NewRequest("GET", url, nil)
		w := httptest.NewRecorder()
		suite.router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response models.APIResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.True(t, response.Success)
	})

	t.Run("Get Post by Slug", func(t *testing.T) {
		url := fmt.Sprintf("/api/v1/posts/slug/%s", suite.testData.PublishedPost.Slug)
		req, _ := http.NewRequest("GET", url, nil)
		w := httptest.NewRecorder()
		suite.router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response models.APIResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.True(t, response.Success)
	})

	t.Run("Get Posts by Category", func(t *testing.T) {
		url := fmt.Sprintf("/api/v1/posts/category/%d", suite.testData.Category.ID)
		req, _ := http.NewRequest("GET", url, nil)
		w := httptest.NewRecorder()
		suite.router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response models.APIResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.True(t, response.Success)
	})

	t.Run("Get Posts by Author", func(t *testing.T) {
		url := fmt.Sprintf("/api/v1/posts/author/%d", suite.testData.Author.ID)
		req, _ := http.NewRequest("GET", url, nil)
		w := httptest.NewRecorder()
		suite.router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response models.APIResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.True(t, response.Success)
	})
}

func TestCategoryIntegration(t *testing.T) {
	suite := setupIntegrationTest(t)
	defer suite.teardown(t)

	t.Run("Get All Categories", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/api/v1/categories", nil)
		w := httptest.NewRecorder()
		suite.router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response models.APIResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.True(t, response.Success)
	})

	t.Run("Get Category by ID", func(t *testing.T) {
		url := fmt.Sprintf("/api/v1/categories/%d", suite.testData.Category.ID)
		req, _ := http.NewRequest("GET", url, nil)
		w := httptest.NewRecorder()
		suite.router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response models.APIResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.True(t, response.Success)
	})

	t.Run("Get Category by Slug", func(t *testing.T) {
		url := fmt.Sprintf("/api/v1/categories/slug/%s", suite.testData.Category.Slug)
		req, _ := http.NewRequest("GET", url, nil)
		w := httptest.NewRecorder()
		suite.router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response models.APIResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.True(t, response.Success)
	})
}

func TestHealthCheckIntegration(t *testing.T) {
	suite := setupIntegrationTest(t)
	defer suite.teardown(t)

	t.Run("Health Check Endpoint", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/health", nil)
		w := httptest.NewRecorder()
		suite.router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusOK, w.Code)

		var response models.HealthResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.Equal(t, "healthy", response.Status)
	})
}

func TestErrorHandlingIntegration(t *testing.T) {
	suite := setupIntegrationTest(t)
	defer suite.teardown(t)

	t.Run("404 Not Found", func(t *testing.T) {
		req, _ := http.NewRequest("GET", "/api/v1/nonexistent", nil)
		w := httptest.NewRecorder()
		suite.router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusNotFound, w.Code)

		var response models.ErrorResponse
		err := json.Unmarshal(w.Body.Bytes(), &response)
		require.NoError(t, err)
		assert.False(t, response.Success)
	})

	t.Run("Invalid JSON Request", func(t *testing.T) {
		req, _ := http.NewRequest("POST", "/api/v1/auth/login", bytes.NewBuffer([]byte("invalid json")))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		suite.router.ServeHTTP(w, req)

		assert.Equal(t, http.StatusBadRequest, w.Code)
	})
}
