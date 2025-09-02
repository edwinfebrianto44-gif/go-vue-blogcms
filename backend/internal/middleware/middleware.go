package middleware

import (
	"net/http"
	"strings"

	"backend/internal/models"
	"backend/internal/services"

	"github.com/gin-gonic/gin"
)

// Enhanced auth middleware with JWT service integration
func AuthMiddleware(jwtService services.JWTService) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Success: false,
				Error:   "Authorization header required",
				Code:    "ERR_AUTH_MISSING_TOKEN",
				Details: "Please provide a valid authentication token",
			})
			c.Abort()
			return
		}

		// Extract token from Authorization header
		token := services.ExtractTokenFromHeader(authHeader)
		if token == "" {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Success: false,
				Error:   "Invalid authorization header format",
				Code:    "ERR_AUTH_INVALID_FORMAT",
				Details: "Authorization header must be in format: Bearer <token>",
			})
			c.Abort()
			return
		}

		// Validate access token
		claims, err := jwtService.ValidateAccessToken(token)
		if err != nil {
			var errorCode string
			var errorMessage string

			if strings.Contains(err.Error(), "expired") {
				errorCode = "ERR_AUTH_TOKEN_EXPIRED"
				errorMessage = "Access token has expired"
			} else if strings.Contains(err.Error(), "invalid") {
				errorCode = "ERR_AUTH_TOKEN_INVALID"
				errorMessage = "Invalid access token"
			} else {
				errorCode = "ERR_AUTH_TOKEN_ERROR"
				errorMessage = "Authentication failed"
			}

			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Success: false,
				Error:   errorMessage,
				Code:    errorCode,
				Details: err.Error(),
			})
			c.Abort()
			return
		}

		// Set user info in context
		c.Set("user_id", claims.UserID)
		c.Set("user_email", claims.Email)
		c.Set("username", claims.Username)
		c.Set("user_role", claims.Role)
		c.Set("jwt_claims", claims)

		c.Next()
	}
}

// Admin-only middleware
func AdminOnly() gin.HandlerFunc {
	return func(c *gin.Context) {
		role, exists := c.Get("user_role")
		if !exists || role != "admin" {
			c.JSON(http.StatusForbidden, models.ErrorResponse{
				Success: false,
				Error:   "Admin access required",
				Code:    "ERR_AUTH_INSUFFICIENT_PERMISSIONS",
				Details: "This endpoint requires administrator privileges",
			})
			c.Abort()
			return
		}
		c.Next()
	}
}

// Author or admin middleware - allows access for authors and admins
func AuthorOrAdminMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		role, exists := c.Get("user_role")
		if !exists {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Success: false,
				Error:   "Authentication required",
				Code:    "ERR_AUTH_REQUIRED",
				Details: "Please authenticate to access this endpoint",
			})
			c.Abort()
			return
		}

		if role != "admin" && role != "author" {
			c.JSON(http.StatusForbidden, models.ErrorResponse{
				Success: false,
				Error:   "Author or admin access required",
				Code:    "ERR_AUTH_INSUFFICIENT_PERMISSIONS",
				Details: "This endpoint requires author or administrator privileges",
			})
			c.Abort()
			return
		}
		c.Next()
	}
}

// Owner or admin middleware - allows access if user owns the resource or is admin
func OwnerOrAdminMiddleware(getResourceOwnerID func(*gin.Context) (uint, error)) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, exists := c.Get("user_id")
		if !exists {
			c.JSON(http.StatusUnauthorized, models.ErrorResponse{
				Success: false,
				Error:   "Authentication required",
				Code:    "ERR_AUTH_REQUIRED",
			})
			c.Abort()
			return
		}

		userRole, _ := c.Get("user_role")

		// Admin can access anything
		if userRole == "admin" {
			c.Next()
			return
		}

		// Check if user owns the resource
		resourceOwnerID, err := getResourceOwnerID(c)
		if err != nil {
			c.JSON(http.StatusInternalServerError, models.ErrorResponse{
				Success: false,
				Error:   "Failed to verify resource ownership",
				Code:    "ERR_AUTH_OWNERSHIP_CHECK",
				Details: err.Error(),
			})
			c.Abort()
			return
		}

		if userID.(uint) != resourceOwnerID {
			c.JSON(http.StatusForbidden, models.ErrorResponse{
				Success: false,
				Error:   "Access denied",
				Code:    "ERR_AUTH_ACCESS_DENIED",
				Details: "You can only access your own resources",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

// Optional auth middleware - doesn't fail if no token provided
func OptionalAuthMiddleware(jwtService services.JWTService) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.Next()
			return
		}

		token := services.ExtractTokenFromHeader(authHeader)
		if token == "" {
			c.Next()
			return
		}

		claims, err := jwtService.ValidateAccessToken(token)
		if err != nil {
			// Don't fail, just continue without auth
			c.Next()
			return
		}

		// Set user info in context if token is valid
		c.Set("user_id", claims.UserID)
		c.Set("user_email", claims.Email)
		c.Set("username", claims.Username)
		c.Set("user_role", claims.Role)
		c.Set("jwt_claims", claims)

		c.Next()
	}
}
