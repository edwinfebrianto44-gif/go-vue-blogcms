import { defineStore } from 'pinia'
import { ref } from 'vue'
import api from '@/services/api'

export const usePostsStore = defineStore('posts', () => {
  const posts = ref([])
  const currentPost = ref(null)
  const isLoading = ref(false)
  const pagination = ref({
    page: 1,
    limit: 10,
    total: 0,
    totalPages: 0
  })

  // Actions
  const fetchPosts = async (params = {}) => {
    isLoading.value = true
    try {
      const response = await api.get('/posts', { params })
      posts.value = response.data.data
      if (response.data.pagination) {
        pagination.value = response.data.pagination
      }
      return response.data
    } catch (error) {
      console.error('Failed to fetch posts:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  const fetchPostBySlug = async (slug) => {
    isLoading.value = true
    try {
      const response = await api.get(`/posts/slug/${slug}`)
      currentPost.value = response.data.data
      return response.data.data
    } catch (error) {
      console.error('Failed to fetch post:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  const fetchPostById = async (id) => {
    isLoading.value = true
    try {
      const response = await api.get(`/posts/${id}`)
      currentPost.value = response.data.data
      return response.data.data
    } catch (error) {
      console.error('Failed to fetch post:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  const createPost = async (postData) => {
    isLoading.value = true
    try {
      const response = await api.post('/posts', postData)
      return { success: true, data: response.data.data }
    } catch (error) {
      console.error('Failed to create post:', error)
      return {
        success: false,
        message: error.response?.data?.error || 'Failed to create post'
      }
    } finally {
      isLoading.value = false
    }
  }

  const updatePost = async (id, postData) => {
    isLoading.value = true
    try {
      const response = await api.put(`/posts/${id}`, postData)
      return { success: true, data: response.data.data }
    } catch (error) {
      console.error('Failed to update post:', error)
      return {
        success: false,
        message: error.response?.data?.error || 'Failed to update post'
      }
    } finally {
      isLoading.value = false
    }
  }

  const deletePost = async (id) => {
    isLoading.value = true
    try {
      await api.delete(`/posts/${id}`)
      // Remove from local state
      posts.value = posts.value.filter(post => post.id !== id)
      return { success: true }
    } catch (error) {
      console.error('Failed to delete post:', error)
      return {
        success: false,
        message: error.response?.data?.error || 'Failed to delete post'
      }
    } finally {
      isLoading.value = false
    }
  }

  const fetchPostsByCategory = async (categoryId, params = {}) => {
    isLoading.value = true
    try {
      const response = await api.get(`/posts/category/${categoryId}`, { params })
      posts.value = response.data.data
      if (response.data.pagination) {
        pagination.value = response.data.pagination
      }
      return response.data
    } catch (error) {
      console.error('Failed to fetch posts by category:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  const fetchPostsByAuthor = async (authorId, params = {}) => {
    isLoading.value = true
    try {
      const response = await api.get(`/posts/author/${authorId}`, { params })
      posts.value = response.data.data
      if (response.data.pagination) {
        pagination.value = response.data.pagination
      }
      return response.data
    } catch (error) {
      console.error('Failed to fetch posts by author:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  return {
    posts,
    currentPost,
    isLoading,
    pagination,
    fetchPosts,
    fetchPostBySlug,
    fetchPostById,
    createPost,
    updatePost,
    deletePost,
    fetchPostsByCategory,
    fetchPostsByAuthor
  }
})
