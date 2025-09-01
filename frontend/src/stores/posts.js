import { defineStore } from 'pinia'
import { ref } from 'vue'
import { postsApi } from '@/services/resources'

export const usePostsStore = defineStore('posts', () => {
  const posts = ref([])
  const currentPost = ref(null)
  const isLoading = ref(false)
  const meta = ref({
    page: 1,
    limit: 10,
    total: 0,
    total_pages: 0
  })

  // Actions
  const fetchPosts = async (params = {}) => {
    isLoading.value = true
    try {
      const response = await postsApi.list(params)
      posts.value = response.data
      if (response.meta) {
        meta.value = response.meta
      }
      return response
    } catch (error) {
      console.error('Failed to fetch posts:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  const searchPosts = async (searchParams) => {
    isLoading.value = true
    try {
      const response = await postsApi.list(searchParams)
      posts.value = response.data
      if (response.meta) {
        meta.value = response.meta
      }
      return response
    } catch (error) {
      console.error('Failed to search posts:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  const fetchPostBySlug = async (slug) => {
    isLoading.value = true
    try {
      const response = await postsApi.getBySlug(slug)
      currentPost.value = response.data
      return response.data
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
      const response = await postsApi.getById(id)
      currentPost.value = response.data
      return response.data
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
      const response = await postsApi.create(postData)
      return { success: true, data: response.data }
    } catch (error) {
      console.error('Failed to create post:', error)
      return {
        success: false,
        message: error.response?.data?.message || error.response?.data?.error || 'Failed to create post'
      }
    } finally {
      isLoading.value = false
    }
  }

  const updatePost = async (id, postData) => {
    isLoading.value = true
    try {
      const response = await postsApi.update(id, postData)
      
      // Update in local state if it exists
      const index = posts.value.findIndex(post => post.id === id)
      if (index !== -1) {
        posts.value[index] = response.data
      }
      
      // Update current post if it's the same
      if (currentPost.value?.id === id) {
        currentPost.value = response.data
      }
      
      return { success: true, data: response.data }
    } catch (error) {
      console.error('Failed to update post:', error)
      return {
        success: false,
        message: error.response?.data?.message || error.response?.data?.error || 'Failed to update post'
      }
    } finally {
      isLoading.value = false
    }
  }

  const deletePost = async (id) => {
    isLoading.value = true
    try {
      await postsApi.delete(id)
      
      // Remove from local state
      posts.value = posts.value.filter(post => post.id !== id)
      
      // Clear current post if it's the same
      if (currentPost.value?.id === id) {
        currentPost.value = null
      }
      
      return { success: true }
    } catch (error) {
      console.error('Failed to delete post:', error)
      return {
        success: false,
        message: error.response?.data?.message || error.response?.data?.error || 'Failed to delete post'
      }
    } finally {
      isLoading.value = false
    }
  }

  const fetchPostsByCategory = async (categoryId, params = {}) => {
    isLoading.value = true
    try {
      const response = await postsApi.getByCategory(categoryId, params)
      posts.value = response.data
      if (response.meta) {
        meta.value = response.meta
      }
      return response
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
      const response = await postsApi.getByAuthor(authorId, params)
      posts.value = response.data
      if (response.meta) {
        meta.value = response.meta
      }
      return response
    } catch (error) {
      console.error('Failed to fetch posts by author:', error)
      throw error
    } finally {
      isLoading.value = false
    }
  }

  const resetState = () => {
    posts.value = []
    currentPost.value = null
    meta.value = {
      page: 1,
      limit: 10,
      total: 0,
      total_pages: 0
    }
  }

  return {
    posts,
    currentPost,
    isLoading,
    meta,
    fetchPosts,
    searchPosts,
    fetchPostBySlug,
    fetchPostById,
    createPost,
    updatePost,
    deletePost,
    fetchPostsByCategory,
    fetchPostsByAuthor,
    resetState
  }
})
