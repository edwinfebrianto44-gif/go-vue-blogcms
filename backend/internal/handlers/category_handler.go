package handlers

import (
	"net/http"
	"strconv"

	"backend/internal/models"
	"backend/internal/services"
	"backend/pkg/utils"

	"github.com/gin-gonic/gin"
)

type CategoryHandler struct {
	categoryService services.CategoryService
}

func NewCategoryHandler(categoryService services.CategoryService) *CategoryHandler {
	return &CategoryHandler{
		categoryService: categoryService,
	}
}

func (h *CategoryHandler) Create(c *gin.Context) {
	var req models.CreateCategoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Invalid request data", err.Error()))
		return
	}

	category, err := h.categoryService.Create(&req)
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Failed to create category", err.Error()))
		return
	}

	c.JSON(http.StatusCreated, utils.SuccessResponse("Category created successfully", category))
}

func (h *CategoryHandler) GetByID(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.ParseUint(idParam, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Invalid category ID", err.Error()))
		return
	}

	category, err := h.categoryService.GetByID(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, utils.ErrorResponse("Category not found", err.Error()))
		return
	}

	c.JSON(http.StatusOK, utils.SuccessResponse("Category retrieved successfully", category))
}

func (h *CategoryHandler) GetBySlug(c *gin.Context) {
	slug := c.Param("slug")

	category, err := h.categoryService.GetBySlug(slug)
	if err != nil {
		c.JSON(http.StatusNotFound, utils.ErrorResponse("Category not found", err.Error()))
		return
	}

	c.JSON(http.StatusOK, utils.SuccessResponse("Category retrieved successfully", category))
}

func (h *CategoryHandler) Update(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.ParseUint(idParam, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Invalid category ID", err.Error()))
		return
	}

	var req models.UpdateCategoryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Invalid request data", err.Error()))
		return
	}

	category, err := h.categoryService.Update(uint(id), &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Failed to update category", err.Error()))
		return
	}

	c.JSON(http.StatusOK, utils.SuccessResponse("Category updated successfully", category))
}

func (h *CategoryHandler) Delete(c *gin.Context) {
	idParam := c.Param("id")
	id, err := strconv.ParseUint(idParam, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Invalid category ID", err.Error()))
		return
	}

	if err := h.categoryService.Delete(uint(id)); err != nil {
		c.JSON(http.StatusBadRequest, utils.ErrorResponse("Failed to delete category", err.Error()))
		return
	}

	c.JSON(http.StatusOK, utils.SuccessResponse("Category deleted successfully", nil))
}

func (h *CategoryHandler) List(c *gin.Context) {
	page, perPage := utils.GetPaginationParams(c)
	
	searchReq := &models.CategorySearchRequest{
		Page:  page,
		Limit: perPage,
		Sort:  c.Query("sort"),
		Query: c.Query("q"),
	}

	categories, total, err := h.categoryService.Search(searchReq)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.ErrorResponse("Failed to retrieve categories", err.Error()))
		return
	}

	response := utils.PaginatedAPIResponse(categories, total, page, perPage, "Categories retrieved successfully")
	c.JSON(http.StatusOK, response)
}
