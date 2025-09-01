import axios from 'axios'

const API_BASE_URL = process.env.VITE_API_BASE_URL || 'http://localhost:8080/api'

export async function generateDynamicRoutes() {
  const routes = []
  
  try {
    // Fetch published posts
    const postsResponse = await axios.get(`${API_BASE_URL}/posts`, {
      params: {
        status: 'published',
        limit: 1000 // Get all published posts
      }
    })
    
    if (postsResponse.data?.data) {
      postsResponse.data.data.forEach(post => {
        routes.push(`/posts/${post.slug}`)
      })
    }
    
    // Fetch categories
    const categoriesResponse = await axios.get(`${API_BASE_URL}/categories`, {
      params: {
        limit: 100 // Get all categories
      }
    })
    
    if (categoriesResponse.data?.data) {
      categoriesResponse.data.data.forEach(category => {
        routes.push(`/categories/${category.slug}`)
      })
    }
    
  } catch (error) {
    console.warn('Failed to fetch dynamic routes:', error.message)
    // Return empty array on error to continue build process
  }
  
  return routes
}

export async function getAllPosts() {
  try {
    const response = await axios.get(`${API_BASE_URL}/posts`, {
      params: {
        status: 'published',
        limit: 1000
      }
    })
    return response.data?.data || []
  } catch (error) {
    console.warn('Failed to fetch posts:', error.message)
    return []
  }
}

export async function getAllCategories() {
  try {
    const response = await axios.get(`${API_BASE_URL}/categories`, {
      params: {
        limit: 100
      }
    })
    return response.data?.data || []
  } catch (error) {
    console.warn('Failed to fetch categories:', error.message)
    return []
  }
}
