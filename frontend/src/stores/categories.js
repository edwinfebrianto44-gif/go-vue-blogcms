import { defineStore } from 'pinia'
import { ref } from 'vue'
import api from '@/services/api'

export const useCategoriesStore = defineStore('categories', () => {
  const categories = ref([])
  const currentCategory = ref(null)
  const isLoading = ref(false)

  // Actions
  const fetchCategories = async () => {
    isLoading.value = true
    try {
      const response = await api.get('/categories')
      categories.value = response.data.data
      return response.data.data
    } catch (error) {
      console.error('Failed to fetch categories:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  const fetchCategoryBySlug = async (slug) => {
    isLoading.value = true
    try {
      const response = await api.get(`/categories/slug/${slug}`)
      currentCategory.value = response.data.data
      return response.data.data
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
      const response = await api.post('/categories', categoryData)
      categories.value.push(response.data.data)
      return { success: true, data: response.data.data }
    } catch (error) {
      console.error('Failed to create category:', error)
      return {
        success: false,
        message: error.response?.data?.error || 'Failed to create category'
      }
    } finally {
      isLoading.value = false
    }
  }

  const updateCategory = async (id, categoryData) => {
    isLoading.value = true
    try {
      const response = await api.put(`/categories/${id}`, categoryData)
      const index = categories.value.findIndex(cat => cat.id === id)
      if (index !== -1) {
        categories.value[index] = response.data.data
      }
      return { success: true, data: response.data.data }
    } catch (error) {
      console.error('Failed to update category:', error)
      return {
        success: false,
        message: error.response?.data?.error || 'Failed to update category'
      }
    } finally {
      isLoading.value = false
    }
  }

  const deleteCategory = async (id) => {
    isLoading.value = true
    try {
      await api.delete(`/categories/${id}`)
      categories.value = categories.value.filter(cat => cat.id !== id)
      return { success: true }
    } catch (error) {
      console.error('Failed to delete category:', error)
      return {
        success: false,
        message: error.response?.data?.error || 'Failed to delete category'
      }
    } finally {
      isLoading.value = false
    }
  }

  return {
    categories,
    currentCategory,
    isLoading,
    fetchCategories,
    fetchCategoryBySlug,
    createCategory,
    updateCategory,
    deleteCategory
  }
})
