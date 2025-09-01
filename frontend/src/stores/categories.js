import { defineStore } from 'pinia'
import { ref } from 'vue'
import { categoriesApi } from '@/services/resources'

export const useCategoriesStore = defineStore('categories', () => {
  const categories = ref([])
  const currentCategory = ref(null)
  const isLoading = ref(false)
  const meta = ref({
    page: 1,
    limit: 50,
    total: 0,
    total_pages: 0
  })

  // Actions
  const fetchCategories = async (params = {}) => {
    isLoading.value = true
    try {
      const response = await categoriesApi.list(params)
      categories.value = response.data
      if (response.meta) {
        meta.value = response.meta
      }
      return response
    } catch (error) {
      console.error('Failed to fetch categories:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  const searchCategories = async (searchParams) => {
    isLoading.value = true
    try {
      const response = await categoriesApi.list(searchParams)
      categories.value = response.data
      if (response.meta) {
        meta.value = response.meta
      }
      return response
    } catch (error) {
      console.error('Failed to search categories:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  const fetchCategoryBySlug = async (slug) => {
    isLoading.value = true
    try {
      const response = await categoriesApi.getBySlug(slug)
      currentCategory.value = response.data
      return response.data
    } catch (error) {
      console.error('Failed to fetch category:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  const fetchCategoryById = async (id) => {
    isLoading.value = true
    try {
      const response = await categoriesApi.getById(id)
      currentCategory.value = response.data
      return response.data
    } catch (error) {
      console.error('Failed to fetch category:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  const createCategory = async (categoryData) => {
    isLoading.value = true
    try {
      const response = await categoriesApi.create(categoryData)
      
      // Add to local state
      categories.value.unshift(response.data)
      
      return { success: true, data: response.data }
    } catch (error) {
      console.error('Failed to create category:', error)
      return {
        success: false,
        message: error.response?.data?.message || error.response?.data?.error || 'Failed to create category'
      }
    } finally {
      isLoading.value = false
    }
  }

  const updateCategory = async (id, categoryData) => {
    isLoading.value = true
    try {
      const response = await categoriesApi.update(id, categoryData)
      
      // Update in local state
      const index = categories.value.findIndex(cat => cat.id === id)
      if (index !== -1) {
        categories.value[index] = response.data
      }
      
      // Update current category if it's the same
      if (currentCategory.value?.id === id) {
        currentCategory.value = response.data
      }
      
      return { success: true, data: response.data }
    } catch (error) {
      console.error('Failed to update category:', error)
      return {
        success: false,
        message: error.response?.data?.message || error.response?.data?.error || 'Failed to update category'
      }
    } finally {
      isLoading.value = false
    }
  }

  const deleteCategory = async (id) => {
    isLoading.value = true
    try {
      await categoriesApi.delete(id)
      
      // Remove from local state
      categories.value = categories.value.filter(cat => cat.id !== id)
      
      // Clear current category if it's the same
      if (currentCategory.value?.id === id) {
        currentCategory.value = null
      }
      
      return { success: true }
    } catch (error) {
      console.error('Failed to delete category:', error)
      return {
        success: false,
        message: error.response?.data?.message || error.response?.data?.error || 'Failed to delete category'
      }
    } finally {
      isLoading.value = false
    }
  }

  const resetState = () => {
    categories.value = []
    currentCategory.value = null
    meta.value = {
      page: 1,
      limit: 50,
      total: 0,
      total_pages: 0
    }
  }

  return {
    categories,
    currentCategory,
    isLoading,
    meta,
    fetchCategories,
    searchCategories,
    fetchCategoryBySlug,
    fetchCategoryById,
    createCategory,
    updateCategory,
    deleteCategory,
    resetState
  }
})
