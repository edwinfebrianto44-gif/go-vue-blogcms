package handlers

import (
	"net/http"
	"strconv"

	"backend/internal/models"
	"backend/internal/services"
	"backend/pkg/utils"

	"github.com/gin-gonic/gin"
)

type CommentHandler struct {
	commentService services.CommentService
}

func NewCommentHandler(commentService services.CommentService) *CommentHandler {
	return &CommentHandler{
		commentService: commentService,
	}
}

func (h *CommentHandler) Create(c *gin.Context) {
	var req models.CreateCommentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Invalid request data", err.Error()))
		return
	}

	userID, _ := c.Get("user_id")

	comment, err := h.commentService.Create(&req, userID.(uint))
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Failed to create comment", err.Error()))
		return
	}

	c.JSON(http.StatusCreated, utils.SuccessResponse("Comment created successfully", comment))
}

func (h *CommentHandler) GetByID(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.ParseUint(idParam, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Invalid comment ID", err.Error()))
		return
	}

	comment, err := h.commentService.GetByID(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, utils.ErrorResponse("Comment not found", err.Error()))
		return
	}

	c.JSON(http.StatusOK, utils.SuccessResponse("Comment retrieved successfully", comment))
}

func (h *CommentHandler) Update(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.ParseUint(idParam, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Invalid comment ID", err.Error()))
		return
	}

	var req models.UpdateCommentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Invalid request data", err.Error()))
		return
	}

	userID, _ := c.Get("user_id")
	userRole, _ := c.Get("user_role")

	comment, err := h.commentService.Update(uint(id), &req, userID.(uint), userRole.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Failed to update comment", err.Error()))
		return
	}

	c.JSON(http.StatusOK, utils.SuccessResponse("Comment updated successfully", comment))
}

func (h *CommentHandler) Delete(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.ParseUint(idParam, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Invalid comment ID", err.Error()))
		return
	}

	userID, _ := c.Get("user_id")
	userRole, _ := c.Get("user_role")

	if err := h.commentService.Delete(uint(id), userID.(uint), userRole.(string)); err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Failed to delete comment", err.Error()))
		return
	}

	c.JSON(http.StatusOK, utils.SuccessResponse("Comment deleted successfully", nil))
}

func (h *CommentHandler) List(c *gin.Context) {
	page, perPage := utils.GetPaginationParams(c)

	// Build filters
	filters := make(map[string]interface{})
	if status := c.Query("status"); status != "" {
		filters["status"] = status
	}
	if postID := c.Query("post_id"); postID != "" {
		if id, err := strconv.ParseUint(postID, 10, 32); err == nil {
			filters["post_id"] = uint(id)
		}
	}

	comments, total, err := h.commentService.List(page, perPage, filters)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.ErrorResponse("Failed to retrieve comments", err.Error()))
		return
	}

	response := utils.PaginationResponse(comments, total, page, perPage)
	c.JSON(http.StatusOK, utils.SuccessResponse("Comments retrieved successfully", response))
}

func (h *CommentHandler) GetByPost(c *gin.Context) {
	postIDParam := c.Param("post_id")
	postID, err := strconv.ParseUint(postIDParam, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Invalid post ID", err.Error()))
		return
	}

	page, perPage := utils.GetPaginationParams(c)

	comments, total, err := h.commentService.GetByPost(uint(postID), page, perPage)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.ErrorResponse("Failed to retrieve comments", err.Error()))
		return
	}

	response := utils.PaginationResponse(comments, total, page, perPage)
	c.JSON(http.StatusOK, utils.SuccessResponse("Comments retrieved successfully", response))
}

func (h *CommentHandler) GetByUser(c *gin.Context) {
	userIDParam := c.Param("user_id")
	userID, err := strconv.ParseUint(userIDParam, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Invalid user ID", err.Error()))
		return
	}

	page, perPage := utils.GetPaginationParams(c)

	comments, total, err := h.commentService.GetByUser(uint(userID), page, perPage)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.ErrorResponse("Failed to retrieve comments", err.Error()))
		return
	}

	response := utils.PaginationResponse(comments, total, page, perPage)
	c.JSON(http.StatusOK, utils.SuccessResponse("Comments retrieved successfully", response))
}
