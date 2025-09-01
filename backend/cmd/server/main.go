package main

import (
	"backend/internal/config"
	"backend/internal/database"
	"backend/internal/handlers"
	"backend/internal/middleware"
	"backend/internal/repositories"
	"backend/internal/routes"
	"backend/internal/services"
	"log"

	"github.com/gin-gonic/gin"
)

func main() {
	// Load configuration
	cfg := config.LoadConfig()

	// Initialize database
	db, err := database.Connect(cfg.DatabaseURL)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Auto migrate (including new RefreshToken model)
	if err := database.AutoMigrate(db); err != nil {
		log.Fatal("Failed to migrate database:", err)
	}

	// Initialize repositories
	userRepo := repositories.NewUserRepository(db)
	postRepo := repositories.NewPostRepository(db)
	categoryRepo := repositories.NewCategoryRepository(db)
	commentRepo := repositories.NewCommentRepository(db)
	refreshTokenRepo := repositories.NewRefreshTokenRepository(db)

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

	// Setup Swagger info
	handlers.SetupSwaggerInfo()

	// Setup Gin router
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.Default()

	// Global middleware
	r.Use(middleware.RequestIDMiddleware())
	r.Use(middleware.SecurityHeadersMiddleware())
	r.Use(middleware.CORSMiddleware())
	r.Use(middleware.ValidationMiddleware())
	r.Use(middleware.ErrorHandlerMiddleware())

	// Rate limiting middleware
	r.Use(middleware.AdvancedRateLimitMiddleware())

	// Setup routes with enhanced security
	routes.SetupRoutes(r, authHandler, postHandler, categoryHandler, commentHandler, uploadHandler, docsHandler, jwtService)

	// Start server
	log.Printf("🚀 BlogCMS Server starting on port %s", cfg.Port)
	log.Printf("🌍 Environment: %s", cfg.Environment)
	log.Printf("📚 API Documentation: http://localhost:%s/api/v1/docs/swagger/", cfg.Port)
	log.Printf("🔐 Security features: JWT with refresh tokens, CORS, Rate limiting, Validation")
	log.Fatal(r.Run(":" + cfg.Port))
}
