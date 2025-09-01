import api from './api'

export const postsApi = {
  // Get posts with pagination and search
  list: async (params = {}) => {
    const response = await api.get('/posts', { params })
    return response.data
  },

  // Get single post by ID
  getById: async (id) => {
    const response = await api.get(`/posts/${id}`)
    return response.data
  },

  // Get single post by slug
  getBySlug: async (slug) => {
    const response = await api.get(`/posts/slug/${slug}`)
    return response.data
  },

  // Create new post
  create: async (postData) => {
    const response = await api.post('/posts', postData)
    return response.data
  },

  // Update post
  update: async (id, postData) => {
    const response = await api.put(`/posts/${id}`, postData)
    return response.data
  },

  // Delete post
  delete: async (id) => {
    const response = await api.delete(`/posts/${id}`)
    return response.data
  },

  // Get posts by author
  getByAuthor: async (authorId, params = {}) => {
    const response = await api.get(`/posts/author/${authorId}`, { params })
    return response.data
  },

  // Get posts by category
  getByCategory: async (categoryId, params = {}) => {
    const response = await api.get(`/posts/category/${categoryId}`, { params })
    return response.data
  }
}

export const categoriesApi = {
  // Get categories with pagination and search
  list: async (params = {}) => {
    const response = await api.get('/categories', { params })
    return response.data
  },

  // Get single category by ID
  getById: async (id) => {
    const response = await api.get(`/categories/${id}`)
    return response.data
  },

  // Get single category by slug
  getBySlug: async (slug) => {
    const response = await api.get(`/categories/slug/${slug}`)
    return response.data
  },

  // Create new category
  create: async (categoryData) => {
    const response = await api.post('/categories', categoryData)
    return response.data
  },

  // Update category
  update: async (id, categoryData) => {
    const response = await api.put(`/categories/${id}`, categoryData)
    return response.data
  },

  // Delete category
  delete: async (id) => {
    const response = await api.delete(`/categories/${id}`)
    return response.data
  }
}

export const commentsApi = {
  // Get comments for a post
  getByPost: async (postId, params = {}) => {
    const response = await api.get(`/posts/${postId}/comments`, { params })
    return response.data
  },

  // Create new comment
  create: async (postId, commentData) => {
    const response = await api.post(`/posts/${postId}/comments`, commentData)
    return response.data
  },

  // Update comment
  update: async (commentId, commentData) => {
    const response = await api.put(`/comments/${commentId}`, commentData)
    return response.data
  },

  // Delete comment
  delete: async (commentId) => {
    const response = await api.delete(`/comments/${commentId}`)
    return response.data
  },

  // Moderate comment (admin/editor only)
  moderate: async (commentId, action) => {
    const response = await api.patch(`/comments/${commentId}/moderate`, { action })
    return response.data
  }
}

export const uploadApi = {
  // Upload image
  uploadImage: async (file, onProgress = null) => {
    const formData = new FormData()
    formData.append('image', file)

    const config = {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    }

    if (onProgress) {
      config.onUploadProgress = (progressEvent) => {
        const percentCompleted = Math.round((progressEvent.loaded * 100) / progressEvent.total)
        onProgress(percentCompleted)
      }
    }

    const response = await api.post('/upload/image', formData, config)
    return response.data
  }
}

export default {
  posts: postsApi,
  categories: categoriesApi,
  comments: commentsApi,
  upload: uploadApi
}
