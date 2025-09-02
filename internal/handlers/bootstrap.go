package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/your-username/go-vue-blogcms/internal/models"
	"github.com/your-username/go-vue-blogcms/internal/services"
	"github.com/your-username/go-vue-blogcms/pkg/logger"
	"golang.org/x/crypto/bcrypt"
)

type BootstrapRequest struct {
	Username string `json:"username" validate:"required,min=3,max=50"`
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required,min=8"`
	Role     string `json:"role" validate:"required,oneof=admin"`
}

type BootstrapResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
	UserID  uint   `json:"user_id,omitempty"`
}

// BootstrapAdmin creates the first admin user if no users exist
func (h *AuthHandler) BootstrapAdmin(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	correlationID := ctx.Value("correlation_id").(string)
	
	logger.Info("Bootstrap admin request received",
		"correlation_id", correlationID,
		"ip", getClientIP(r))

	// Check if any users already exist
	userCount, err := h.userService.GetUserCount(ctx)
	if err != nil {
		logger.Error("Failed to check user count",
			"error", err,
			"correlation_id", correlationID)
		writeErrorResponse(w, http.StatusInternalServerError, "Internal server error")
		return
	}

	if userCount > 0 {
		logger.Warn("Bootstrap admin attempted but users already exist",
			"user_count", userCount,
			"correlation_id", correlationID,
			"ip", getClientIP(r))
		writeErrorResponse(w, http.StatusForbidden, "Admin user already exists")
		return
	}

	var req BootstrapRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		logger.Error("Invalid request body",
			"error", err,
			"correlation_id", correlationID)
		writeErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Validate request
	if err := h.validator.Struct(req); err != nil {
		logger.Error("Validation failed",
			"error", err,
			"correlation_id", correlationID)
		writeErrorResponse(w, http.StatusBadRequest, "Validation failed: "+err.Error())
		return
	}

	// Only allow admin role for bootstrap
	if req.Role != "admin" {
		logger.Error("Invalid role for bootstrap",
			"role", req.Role,
			"correlation_id", correlationID)
		writeErrorResponse(w, http.StatusBadRequest, "Only admin role is allowed for bootstrap")
		return
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		logger.Error("Failed to hash password",
			"error", err,
			"correlation_id", correlationID)
		writeErrorResponse(w, http.StatusInternalServerError, "Failed to process password")
		return
	}

	// Create admin user
	user := &models.User{
		Username:  req.Username,
		Email:     req.Email,
		Password:  string(hashedPassword),
		Role:      req.Role,
		IsActive:  true,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	createdUser, err := h.userService.CreateUser(ctx, user)
	if err != nil {
		logger.Error("Failed to create admin user",
			"error", err,
			"correlation_id", correlationID)
		writeErrorResponse(w, http.StatusInternalServerError, "Failed to create admin user")
		return
	}

	logger.Info("Admin user bootstrapped successfully",
		"user_id", createdUser.ID,
		"username", createdUser.Username,
		"email", createdUser.Email,
		"correlation_id", correlationID)

	response := BootstrapResponse{
		Success: true,
		Message: "Admin user created successfully",
		UserID:  createdUser.ID,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

// Helper function to get client IP
func getClientIP(r *http.Request) string {
	// Check X-Forwarded-For header first (for load balancers/proxies)
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		return xff
	}
	
	// Check X-Real-IP header
	if xri := r.Header.Get("X-Real-IP"); xri != "" {
		return xri
	}
	
	// Fall back to RemoteAddr
	return r.RemoteAddr
}
