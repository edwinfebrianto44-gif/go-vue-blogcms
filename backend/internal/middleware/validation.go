package middleware

import (
	"net/http"
	"reflect"
	"strings"

	"backend/internal/models"

	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
)

var validate *validator.Validate

func init() {
	validate = validator.New()
	
	// Register custom field name function
	validate.RegisterTagNameFunc(func(fld reflect.StructField) string {
		name := strings.SplitN(fld.Tag.Get("json"), ",", 2)[0]
		if name == "-" {
			return ""
		}
		return name
	})

	// Register custom validators
	validate.RegisterValidation("alphanum_space", validateAlphaNumSpace)
	validate.RegisterValidation("slug", validateSlug)
	validate.RegisterValidation("strong_password", validateStrongPassword)
}

// ValidationMiddleware provides comprehensive request validation
func ValidationMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Set("validator", validate)
		c.Next()
	}
}

// ValidateStruct validates a struct using the validator instance
func ValidateStruct(s interface{}) []models.ValidationError {
	var validationErrors []models.ValidationError

	err := validate.Struct(s)
	if err != nil {
		for _, err := range err.(validator.ValidationErrors) {
			var element models.ValidationError
			element.Field = err.Field()
			element.Message = getValidationMessage(err)
			if err.Value() != nil {
				element.Value = err.Value().(string)
			}
			validationErrors = append(validationErrors, element)
		}
	}

	return validationErrors
}

// getValidationMessage returns user-friendly validation messages
func getValidationMessage(err validator.FieldError) string {
	switch err.Tag() {
	case "required":
		return err.Field() + " is required"
	case "email":
		return err.Field() + " must be a valid email address"
	case "min":
		return err.Field() + " must be at least " + err.Param() + " characters long"
	case "max":
		return err.Field() + " must not exceed " + err.Param() + " characters"
	case "alphanum":
		return err.Field() + " must contain only letters and numbers"
	case "oneof":
		return err.Field() + " must be one of: " + err.Param()
	case "gt":
		return err.Field() + " must be greater than " + err.Param()
	case "gte":
		return err.Field() + " must be greater than or equal to " + err.Param()
	case "lt":
		return err.Field() + " must be less than " + err.Param()
	case "lte":
		return err.Field() + " must be less than or equal to " + err.Param()
	case "eqfield":
		return err.Field() + " must match " + err.Param()
	case "alphanum_space":
		return err.Field() + " must contain only letters, numbers, and spaces"
	case "slug":
		return err.Field() + " must be a valid slug (lowercase letters, numbers, and hyphens)"
	case "strong_password":
		return err.Field() + " must contain at least one uppercase letter, one lowercase letter, one number, and one special character"
	default:
		return err.Field() + " is invalid"
	}
}

// Custom validators
func validateAlphaNumSpace(fl validator.FieldLevel) bool {
	value := fl.Field().String()
	for _, char := range value {
		if !((char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || 
			 (char >= '0' && char <= '9') || char == ' ') {
			return false
		}
	}
	return true
}

func validateSlug(fl validator.FieldLevel) bool {
	value := fl.Field().String()
	for _, char := range value {
		if !((char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') || char == '-') {
			return false
		}
	}
	return true
}

func validateStrongPassword(fl validator.FieldLevel) bool {
	password := fl.Field().String()
	
	if len(password) < 8 {
		return false
	}

	var hasUpper, hasLower, hasNumber, hasSpecial bool
	
	for _, char := range password {
		switch {
		case char >= 'A' && char <= 'Z':
			hasUpper = true
		case char >= 'a' && char <= 'z':
			hasLower = true
		case char >= '0' && char <= '9':
			hasNumber = true
		case strings.ContainsRune("!@#$%^&*()_+-=[]{}|;:,.<>?", char):
			hasSpecial = true
		}
	}

	return hasUpper && hasLower && hasNumber && hasSpecial
}

// ErrorHandler middleware for consistent error responses
func ErrorHandlerMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()

		// Handle any errors that occurred during request processing
		if len(c.Errors) > 0 {
			err := c.Errors.Last()
			
			switch err.Type {
			case gin.ErrorTypeBind:
				// Validation errors from gin binding
				if validationErrors := extractValidationErrors(err.Err); len(validationErrors) > 0 {
					c.JSON(http.StatusBadRequest, models.ValidationErrorResponse{
						Success: false,
						Error:   "Validation failed",
						Code:    "ERR_VALIDATION",
						Details: validationErrors,
					})
					return
				}
				
				c.JSON(http.StatusBadRequest, models.ErrorResponse{
					Success: false,
					Error:   "Invalid request data",
					Code:    "ERR_INVALID_REQUEST",
					Details: err.Error(),
				})
			case gin.ErrorTypePublic:
				c.JSON(http.StatusInternalServerError, models.ErrorResponse{
					Success: false,
					Error:   "Internal server error",
					Code:    "ERR_INTERNAL",
					Details: err.Error(),
				})
			default:
				c.JSON(http.StatusInternalServerError, models.ErrorResponse{
					Success: false,
					Error:   "Internal server error",
					Code:    "ERR_INTERNAL",
				})
			}
		}
	}
}

// extractValidationErrors extracts validation errors from gin binding errors
func extractValidationErrors(err error) []models.ValidationError {
	var validationErrors []models.ValidationError

	if validatorErrors, ok := err.(validator.ValidationErrors); ok {
		for _, err := range validatorErrors {
			var element models.ValidationError
			element.Field = err.Field()
			element.Message = getValidationMessage(err)
			if err.Value() != nil && err.Value() != "" {
				element.Value = err.Value().(string)
			}
			validationErrors = append(validationErrors, element)
		}
	}

	return validationErrors
}

// SanitizeInput middleware to clean user input
func SanitizeInputMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Add sanitization logic here if needed
		// For now, we rely on validation
		c.Next()
	}
}
