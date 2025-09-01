package handlers

import (
	"net/http"

	"backend/internal/middleware"
	"backend/internal/models"
	"backend/internal/services"

	"github.com/gin-gonic/gin"
)

type AuthHandler struct {
	authService services.AuthService
}

func NewAuthHandler(authService services.AuthService) *AuthHandler {
	return &AuthHandler{
		authService: authService,
	}
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req models.RegisterRequest
	
	// Bind and validate JSON
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Success: false,
			Error:   "Invalid request data",
			Code:    "ERR_VALIDATION_FAILED",
			Details: err.Error(),
		})
		return
	}

	// Additional validation using custom validator
	if validationErrors := middleware.ValidateStruct(&req); len(validationErrors) > 0 {
		c.JSON(http.StatusBadRequest, models.ValidationErrorResponse{
			Success: false,
			Error:   "Validation failed",
			Code:    "ERR_VALIDATION_FAILED",
			Details: validationErrors,
		})
		return
	}

	user, err := h.authService.Register(&req)
	if err != nil {
		var errorCode string
		switch err.Error() {
		case "username already exists":
			errorCode = "ERR_USERNAME_EXISTS"
		case "email already exists":
			errorCode = "ERR_EMAIL_EXISTS"
		default:
			errorCode = "ERR_REGISTRATION_FAILED"
		}

		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Success: false,
			Error:   err.Error(),
			Code:    errorCode,
		})
		return
	}

	c.JSON(http.StatusCreated, models.APIResponse{
		Success: true,
		Message: "User registered successfully",
		Data:    user,
	})
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req models.LoginRequest
	
	// Bind and validate JSON
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Success: false,
			Error:   "Invalid request data",
			Code:    "ERR_VALIDATION_FAILED",
			Details: err.Error(),
		})
		return
	}

	// Additional validation using custom validator
	if validationErrors := middleware.ValidateStruct(&req); len(validationErrors) > 0 {
		c.JSON(http.StatusBadRequest, models.ValidationErrorResponse{
			Success: false,
			Error:   "Validation failed",
			Code:    "ERR_VALIDATION_FAILED",
			Details: validationErrors,
		})
		return
	}

	authResponse, err := h.authService.Login(&req)
	if err != nil {
		var errorCode string
		if err.Error() == "invalid email or password" {
			errorCode = "ERR_INVALID_CREDENTIALS"
		} else {
			errorCode = "ERR_LOGIN_FAILED"
		}

		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Success: false,
			Error:   err.Error(),
			Code:    errorCode,
		})
		return
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Message: "Login successful",
		Data:    authResponse,
	})
}

func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req models.RefreshTokenRequest
	
	// Bind and validate JSON
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Success: false,
			Error:   "Invalid request data",
			Code:    "ERR_VALIDATION_FAILED",
			Details: err.Error(),
		})
		return
	}

	// Additional validation using custom validator
	if validationErrors := middleware.ValidateStruct(&req); len(validationErrors) > 0 {
		c.JSON(http.StatusBadRequest, models.ValidationErrorResponse{
			Success: false,
			Error:   "Validation failed",
			Code:    "ERR_VALIDATION_FAILED",
			Details: validationErrors,
		})
		return
	}

	refreshResponse, err := h.authService.RefreshToken(&req)
	if err != nil {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Success: false,
			Error:   err.Error(),
			Code:    "ERR_REFRESH_TOKEN_INVALID",
		})
		return
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Message: "Token refreshed successfully",
		Data:    refreshResponse,
	})
}

func (h *AuthHandler) Logout(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Success: false,
			Error:   "Authentication required",
			Code:    "ERR_AUTH_REQUIRED",
		})
		return
	}

	// Get refresh token from request body (optional)
	var req struct {
		RefreshToken string `json:"refresh_token"`
	}
	c.ShouldBindJSON(&req)

	err := h.authService.Logout(userID.(uint), req.RefreshToken)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Success: false,
			Error:   "Logout failed",
			Code:    "ERR_LOGOUT_FAILED",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Message: "Logged out successfully",
	})
}

func (h *AuthHandler) LogoutAll(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Success: false,
			Error:   "Authentication required",
			Code:    "ERR_AUTH_REQUIRED",
		})
		return
	}

	err := h.authService.LogoutAll(userID.(uint))
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Success: false,
			Error:   "Logout from all devices failed",
			Code:    "ERR_LOGOUT_ALL_FAILED",
			Details: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Message: "Logged out from all devices successfully",
	})
}

func (h *AuthHandler) GetProfile(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Success: false,
			Error:   "Authentication required",
			Code:    "ERR_AUTH_REQUIRED",
		})
		return
	}

	profile, err := h.authService.GetProfile(userID.(uint))
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Success: false,
			Error:   err.Error(),
			Code:    "ERR_PROFILE_FETCH_FAILED",
		})
		return
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Message: "Profile retrieved successfully",
		Data:    profile,
	})
}

func (h *AuthHandler) UpdateProfile(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Success: false,
			Error:   "Authentication required",
			Code:    "ERR_AUTH_REQUIRED",
		})
		return
	}

	var req models.UpdateProfileRequest
	
	// Bind and validate JSON
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Success: false,
			Error:   "Invalid request data",
			Code:    "ERR_VALIDATION_FAILED",
			Details: err.Error(),
		})
		return
	}

	// Additional validation using custom validator
	if validationErrors := middleware.ValidateStruct(&req); len(validationErrors) > 0 {
		c.JSON(http.StatusBadRequest, models.ValidationErrorResponse{
			Success: false,
			Error:   "Validation failed",
			Code:    "ERR_VALIDATION_FAILED",
			Details: validationErrors,
		})
		return
	}

	profile, err := h.authService.UpdateProfile(userID.(uint), &req)
	if err != nil {
		var errorCode string
		switch err.Error() {
		case "username already exists":
			errorCode = "ERR_USERNAME_EXISTS"
		case "email already exists":
			errorCode = "ERR_EMAIL_EXISTS"
		default:
			errorCode = "ERR_PROFILE_UPDATE_FAILED"
		}

		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Success: false,
			Error:   err.Error(),
			Code:    errorCode,
		})
		return
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Message: "Profile updated successfully",
		Data:    profile,
	})
}

func (h *AuthHandler) ChangePassword(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, models.ErrorResponse{
			Success: false,
			Error:   "Authentication required",
			Code:    "ERR_AUTH_REQUIRED",
		})
		return
	}

	var req models.ChangePasswordRequest
	
	// Bind and validate JSON
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Success: false,
			Error:   "Invalid request data",
			Code:    "ERR_VALIDATION_FAILED",
			Details: err.Error(),
		})
		return
	}

	// Additional validation using custom validator
	if validationErrors := middleware.ValidateStruct(&req); len(validationErrors) > 0 {
		c.JSON(http.StatusBadRequest, models.ValidationErrorResponse{
			Success: false,
			Error:   "Validation failed",
			Code:    "ERR_VALIDATION_FAILED",
			Details: validationErrors,
		})
		return
	}

	err := h.authService.ChangePassword(userID.(uint), &req)
	if err != nil {
		var errorCode string
		if err.Error() == "current password is incorrect" {
			errorCode = "ERR_CURRENT_PASSWORD_INCORRECT"
		} else {
			errorCode = "ERR_PASSWORD_CHANGE_FAILED"
		}

		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Success: false,
			Error:   err.Error(),
			Code:    errorCode,
		})
		return
	}

	c.JSON(http.StatusOK, models.APIResponse{
		Success: true,
		Message: "Password changed successfully",
	})
}
