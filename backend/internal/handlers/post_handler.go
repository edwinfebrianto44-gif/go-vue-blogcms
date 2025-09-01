package handlers

import (
	"net/http"
	"strconv"

	"backend/internal/models"
	"backend/internal/services"
	"backend/pkg/utils"

	"github.com/gin-gonic/gin"
)

type PostHandler struct {
	postService services.PostService
}

func NewPostHandler(postService services.PostService) *PostHandler {
	return &PostHandler{
		postService: postService,
	}
}

func (h *PostHandler) Create(c *gin.Context) {
	var req models.CreatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Invalid request data", err.Error()))
		return
	}

	userID, _ := c.Get("user_id")
	authorID := userID.(uint)

	post, err := h.postService.Create(&req, authorID)
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Failed to create post", err.Error()))
		return
	}

	c.JSON(http.StatusCreated, utils.SuccessResponse("Post created successfully", post))
}

func (h *PostHandler) GetByID(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.ParseUint(idParam, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Invalid post ID", err.Error()))
		return
	}

	post, err := h.postService.GetByID(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, utils.ErrorResponse("Post not found", err.Error()))
		return
	}

	c.JSON(http.StatusOK, utils.SuccessResponse("Post retrieved successfully", post))
}

func (h *PostHandler) GetBySlug(c *gin.Context) {
	slug := c.Param("slug")

	post, err := h.postService.GetBySlug(slug)
	if err != nil {
		c.JSON(http.StatusNotFound, utils.ErrorResponse("Post not found", err.Error()))
		return
	}

	c.JSON(http.StatusOK, utils.SuccessResponse("Post retrieved successfully", post))
}

func (h *PostHandler) Update(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.ParseUint(idParam, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Invalid post ID", err.Error()))
		return
	}

	var req models.UpdatePostRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Invalid request data", err.Error()))
		return
	}

	userID, _ := c.Get("user_id")
	userRole, _ := c.Get("user_role")

	post, err := h.postService.Update(uint(id), &req, userID.(uint), userRole.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Failed to update post", err.Error()))
		return
	}

	c.JSON(http.StatusOK, utils.SuccessResponse("Post updated successfully", post))
}

func (h *PostHandler) Delete(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.ParseUint(idParam, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Invalid post ID", err.Error()))
		return
	}

	userID, _ := c.Get("user_id")
	userRole, _ := c.Get("user_role")

	if err := h.postService.Delete(uint(id), userID.(uint), userRole.(string)); err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Failed to delete post", err.Error()))
		return
	}

	c.JSON(http.StatusOK, utils.SuccessResponse("Post deleted successfully", nil))
}

func (h *PostHandler) List(c *gin.Context) {
	page, perPage := utils.GetPaginationParams(c)

	// Build filters
	filters := make(map[string]interface{})
	if status := c.Query("status"); status != "" {
		filters["status"] = status
	}
	if categoryID := c.Query("category_id"); categoryID != "" {
		if id, err := strconv.ParseUint(categoryID, 10, 32); err == nil {
			filters["category_id"] = uint(id)
		}
	}

	posts, total, err := h.postService.List(page, perPage, filters)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.ErrorResponse("Failed to retrieve posts", err.Error()))
		return
	}

	response := utils.PaginationResponse(posts, total, page, perPage)
	c.JSON(http.StatusOK, utils.SuccessResponse("Posts retrieved successfully", response))
}

func (h *PostHandler) GetByAuthor(c *gin.Context) {
	authorIDParam := c.Param("author_id")
	authorID, err := strconv.ParseUint(authorIDParam, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Invalid author ID", err.Error()))
		return
	}

	page, perPage := utils.GetPaginationParams(c)

	posts, total, err := h.postService.GetByAuthor(uint(authorID), page, perPage)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.ErrorResponse("Failed to retrieve posts", err.Error()))
		return
	}

	response := utils.PaginationResponse(posts, total, page, perPage)
	c.JSON(http.StatusOK, utils.SuccessResponse("Posts retrieved successfully", response))
}

func (h *PostHandler) GetByCategory(c *gin.Context) {
	categoryIDParam := c.Param("category_id")
	categoryID, err := strconv.ParseUint(categoryIDParam, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Invalid category ID", err.Error()))
		return
	}

	page, perPage := utils.GetPaginationParams(c)

	posts, total, err := h.postService.GetByCategory(uint(categoryID), page, perPage)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.ErrorResponse("Failed to retrieve posts", err.Error()))
		return
	}

	response := utils.PaginationResponse(posts, total, page, perPage)
	c.JSON(http.StatusOK, utils.SuccessResponse("Posts retrieved successfully", response))
}
