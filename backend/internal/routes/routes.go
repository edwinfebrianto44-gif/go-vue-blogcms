package routes

import (
	"backend/internal/handlers"
	"backend/internal/middleware"
	"backend/internal/models"
	"backend/internal/services"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

func SetupRoutes(
	r *gin.Engine,
	authHandler *handlers.AuthHandler,
	postHandler *handlers.PostHandler,
	categoryHandler *handlers.CategoryHandler,
	commentHandler *handlers.CommentHandler,
	docsHandler *handlers.DocsHandler,
	jwtService services.JWTService,
) {
	// Health check with detailed information
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, models.HealthResponse{
			Status:    "healthy",
			Timestamp: time.Now(),
			Version:   "1.0.0",
			Services: map[string]string{
				"database":     "connected",
				"auth":         "enabled",
				"rate_limit":   "active",
				"cors":         "configured",
				"validation":   "enabled",
			},
		})
	})

	// API v1 routes
	v1 := r.Group("/api/v1")

	// Documentation routes (public, with light rate limiting)
	docs := v1.Group("/docs")
	docs.Use(middleware.RateLimitMiddleware(30)) // 30 requests per minute for docs
	docsHandler.SetupRoutes(docs)

	// Auth routes (public, with strict rate limiting)
	auth := v1.Group("/auth")
	auth.Use(middleware.RateLimitMiddleware(10)) // 10 requests per minute for auth
	{
		auth.POST("/register", authHandler.Register)
		auth.POST("/login", authHandler.Login)
		auth.POST("/refresh", authHandler.RefreshToken)
		
		// Protected auth routes
		authProtected := auth.Group("")
		authProtected.Use(middleware.AuthMiddleware(jwtService))
		{
			authProtected.GET("/profile", authHandler.GetProfile)
			authProtected.PUT("/profile", authHandler.UpdateProfile)
			authProtected.POST("/change-password", authHandler.ChangePassword)
			authProtected.POST("/logout", authHandler.Logout)
			authProtected.POST("/logout-all", authHandler.LogoutAll)
		}
	}

	// Categories routes
	categories := v1.Group("/categories")
	{
		// Public routes (read-only)
		categories.GET("", categoryHandler.List)
		categories.GET("/:id", categoryHandler.GetByID)
		categories.GET("/slug/:slug", categoryHandler.GetBySlug)
		
		// Protected routes (admin only)
		categoriesProtected := categories.Group("")
		categoriesProtected.Use(middleware.AuthMiddleware(jwtService))
		categoriesProtected.Use(middleware.AdminOnly())
		{
			categoriesProtected.POST("", categoryHandler.Create)
			categoriesProtected.PUT("/:id", categoryHandler.Update)
			categoriesProtected.DELETE("/:id", categoryHandler.Delete)
		}
	}

	// Posts routes
	posts := v1.Group("/posts")
	{
		// Public routes (read-only)
		posts.GET("", postHandler.List)
		posts.GET("/:id", postHandler.GetByID)
		posts.GET("/slug/:slug", postHandler.GetBySlug)
		posts.GET("/author/:author_id", postHandler.GetByAuthor)
		posts.GET("/category/:category_id", postHandler.GetByCategory)
		
		// Protected routes (authenticated users)
		postsProtected := posts.Group("")
		postsProtected.Use(middleware.AuthMiddleware(jwtService))
		{
			postsProtected.POST("", postHandler.Create)
			
			// Owner or admin can update/delete
			postsProtected.PUT("/:id", middleware.OwnerOrAdminMiddleware(getPostOwnerID), postHandler.Update)
			postsProtected.DELETE("/:id", middleware.OwnerOrAdminMiddleware(getPostOwnerID), postHandler.Delete)
		}
	}

	// Comments routes
	comments := v1.Group("/comments")
	{
		// Public routes (read-only)
		comments.GET("", commentHandler.List)
		comments.GET("/:id", commentHandler.GetByID)
		comments.GET("/post/:post_id", commentHandler.GetByPost)
		comments.GET("/user/:user_id", commentHandler.GetByUser)
		
		// Protected routes (authenticated users)
		commentsProtected := comments.Group("")
		commentsProtected.Use(middleware.AuthMiddleware(jwtService))
		{
			commentsProtected.POST("", commentHandler.Create)
			
			// Owner or admin can update/delete
			commentsProtected.PUT("/:id", middleware.OwnerOrAdminMiddleware(getCommentOwnerID), commentHandler.Update)
			commentsProtected.DELETE("/:id", middleware.OwnerOrAdminMiddleware(getCommentOwnerID), commentHandler.Delete)
		}
	}

	// Admin routes (admin only)
	admin := v1.Group("/admin")
	admin.Use(middleware.AuthMiddleware(jwtService))
	admin.Use(middleware.AdminOnly())
	{
		// User management
		admin.GET("/users", func(c *gin.Context) {
			// TODO: Implement user list endpoint
			c.JSON(http.StatusOK, models.APIResponse{
				Success: true,
				Message: "Admin endpoint - user list",
				Data:    []string{"Coming soon"},
			})
		})
		
		// System statistics
		admin.GET("/stats", func(c *gin.Context) {
			// TODO: Implement system statistics
			c.JSON(http.StatusOK, models.APIResponse{
				Success: true,
				Message: "Admin endpoint - system statistics",
				Data:    map[string]interface{}{"status": "Coming soon"},
			})
		})
	}

	// 404 handler
	r.NoRoute(func(c *gin.Context) {
		c.JSON(http.StatusNotFound, models.ErrorResponse{
			Success: false,
			Error:   "Endpoint not found",
			Code:    "ERR_NOT_FOUND",
			Details: "The requested endpoint does not exist",
		})
	})
}

// Helper functions to get resource owner IDs
func getPostOwnerID(c *gin.Context) (uint, error) {
	// TODO: Implement logic to get post owner ID from database
	// This should query the post by ID and return the author_id
	// For now, return a dummy implementation
	return 1, nil
}

func getCommentOwnerID(c *gin.Context) (uint, error) {
	// TODO: Implement logic to get comment owner ID from database
	// This should query the comment by ID and return the user_id
	// For now, return a dummy implementation
	return 1, nil
}
