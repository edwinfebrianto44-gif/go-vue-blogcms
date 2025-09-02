package main

import (
	"backend/internal/config"
	"backend/internal/database"
	"backend/internal/handlers"
	"backend/internal/middleware"
	"backend/internal/repositories"
	"backend/internal/routes"
	"backend/internal/services"
	"backend/pkg/logger"
	"backend/pkg/metrics"
	"fmt"
	"log"
	"runtime"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

func main() {
	// Load configuration
	cfg := config.LoadConfig()

	// Initialize structured logging
	if err := logger.InitLogger(cfg.Environment); err != nil {
		log.Fatal("Failed to initialize logger:", err)
	}
	defer logger.Sync()

	// Get logger instance
	appLogger := logger.GetLogger()
	appLogger.Info("Starting BlogCMS API Server",
		zap.String("environment", cfg.Environment),
		zap.String("port", cfg.Server.Port),
	)

	// Initialize metrics
	metrics.SetSystemInfo("1.0.0", runtime.Version(), cfg.Environment)

	// Initialize database
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		cfg.Database.User,
		cfg.Database.Password,
		cfg.Database.Host,
		cfg.Database.Port,
		cfg.Database.Name,
	)

	db, err := database.Connect(dsn)
	if err != nil {
		appLogger.Fatal("Failed to connect to database", zap.Error(err))
	}

	appLogger.Info("Database connected successfully",
		zap.String("host", cfg.Database.Host),
		zap.String("database", cfg.Database.Name),
	)

	// Auto migrate (including new RefreshToken model)
	if err := database.AutoMigrate(db); err != nil {
		appLogger.Fatal("Failed to migrate database", zap.Error(err))
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
	storageService := services.NewStorageService(cfg)

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(authService)
	postHandler := handlers.NewPostHandler(postService)
	categoryHandler := handlers.NewCategoryHandler(categoryService)
	commentHandler := handlers.NewCommentHandler(commentService)
	uploadHandler := handlers.NewUploadHandler(storageService, cfg)
	docsHandler := handlers.NewDocsHandler()
	healthHandler := handlers.NewHealthHandler(db)
	metricsHandler := handlers.NewMetricsHandler()

	appLogger.Info("All handlers initialized successfully")

	// Setup Swagger info
	handlers.SetupSwaggerInfo()

	// Setup Gin router
	if cfg.Environment == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.New()

	// Observability middleware (applied first for complete request tracking)
	r.Use(middleware.CorrelationIDMiddleware()) // X-Request-ID correlation
	r.Use(middleware.LoggingMiddleware())       // Structured logging
	r.Use(middleware.MetricsMiddleware())       // Prometheus metrics

	// Core middleware
	r.Use(middleware.RequestIDMiddleware())
	r.Use(middleware.SecurityHeadersMiddleware())
	r.Use(middleware.CORSMiddleware())
	r.Use(middleware.ValidationMiddleware())
	r.Use(middleware.ErrorHandlerMiddleware())

	// Rate limiting middleware
	r.Use(middleware.AdvancedRateLimitMiddleware())

	appLogger.Info("Middleware stack configured",
		zap.Bool("cors_enabled", true),
		zap.Bool("rate_limiting_enabled", true),
		zap.Bool("structured_logging_enabled", true),
		zap.Bool("metrics_enabled", true),
	)

	// Setup routes with enhanced observability
	routes.SetupRoutes(r, authHandler, postHandler, categoryHandler, commentHandler,
		uploadHandler, docsHandler, healthHandler, metricsHandler, jwtService)

	// Start server
	appLogger.Info("BlogCMS Server starting",
		zap.String("port", cfg.Server.Port),
		zap.String("environment", cfg.App.Environment),
		zap.String("docs_url", fmt.Sprintf("http://localhost:%s/api/v1/docs/swagger/", cfg.Server.Port)),
		zap.String("health_url", fmt.Sprintf("http://localhost:%s/health", cfg.Server.Port)),
		zap.String("metrics_url", fmt.Sprintf("http://localhost:%s/metrics", cfg.Server.Port)),
	)

	log.Fatal(r.Run(":" + cfg.Server.Port))
}
