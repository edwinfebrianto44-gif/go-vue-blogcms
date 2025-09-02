import axios from 'axios'

// Create axios instance with environment configuration
const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api',
  timeout: parseInt(import.meta.env.VITE_API_TIMEOUT) || 10000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Track if refresh is in progress to avoid multiple refresh calls
let isRefreshing = false
let failedQueue = []

const processQueue = (error, token = null) => {
  failedQueue.forEach(prom => {
    if (error) {
      prom.reject(error)
    } else {
      prom.resolve(token)
    }
  })
  
  failedQueue = []
}

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    // Only access localStorage on client side
    const token = typeof window !== 'undefined' && typeof localStorage !== 'undefined' 
      ? localStorage.getItem('accessToken') 
      : null
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor to handle errors and token refresh
api.interceptors.response.use(
  (response) => {
    return response
  },
  async (error) => {
    const originalRequest = error.config

    // Handle 401 errors (unauthorized) - try to refresh token
    if (error.response?.status === 401 && !originalRequest._retry) {
      if (isRefreshing) {
        // If refresh is already in progress, queue this request
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject })
        }).then(token => {
          originalRequest.headers.Authorization = `Bearer ${token}`
          return api(originalRequest)
        }).catch(err => {
          return Promise.reject(err)
        })
      }

      originalRequest._retry = true
      isRefreshing = true

      const refreshToken = typeof window !== 'undefined' && typeof localStorage !== 'undefined' 
        ? localStorage.getItem('refreshToken') 
        : null
      
      if (refreshToken) {
        try {
          const response = await axios.post(
            `${import.meta.env.VITE_API_BASE_URL || '/api'}/auth/refresh`,
            { refresh_token: refreshToken },
            {
              headers: { 'Content-Type': 'application/json' }
            }
          )

          const { access_token, refresh_token: newRefreshToken } = response.data.data
          
          // Update tokens in localStorage (only on client side)
          if (typeof window !== 'undefined' && typeof localStorage !== 'undefined') {
            localStorage.setItem('accessToken', access_token)
            if (newRefreshToken) {
              localStorage.setItem('refreshToken', newRefreshToken)
            }
          }

          // Update default authorization header
          api.defaults.headers.common['Authorization'] = `Bearer ${access_token}`
          
          // Process queued requests
          processQueue(null, access_token)
          
          // Retry original request
          originalRequest.headers.Authorization = `Bearer ${access_token}`
          return api(originalRequest)
          
        } catch (refreshError) {
          // Refresh failed, logout user
          processQueue(refreshError, null)
          clearAuthData()
          redirectToLogin()
          return Promise.reject(refreshError)
        } finally {
          isRefreshing = false
        }
      } else {
        // No refresh token, logout user
        clearAuthData()
        redirectToLogin()
        return Promise.reject(error)
      }
    }

    // Handle other errors
    if (error.response?.status === 403) {
      // Forbidden - user doesn't have permission
      console.error('Access forbidden:', error.response.data)
    } else if (error.response?.status >= 500) {
      // Server errors
      console.error('Server error:', error.response.data)
    }
    
    return Promise.reject(error)
  }
)

// Utility functions
const clearAuthData = () => {
  if (typeof window !== 'undefined' && typeof localStorage !== 'undefined') {
    localStorage.removeItem('accessToken')
    localStorage.removeItem('refreshToken')
    localStorage.removeItem('user')
  }
  delete api.defaults.headers.common['Authorization']
}

const redirectToLogin = () => {
  // Only redirect on client side
  if (typeof window !== 'undefined') {
    // Avoid redirect loops
    if (!window.location.pathname.includes('/login') && !window.location.pathname.includes('/register')) {
      // Store current location for redirect after login
      if (typeof localStorage !== 'undefined') {
        localStorage.setItem('redirectPath', window.location.pathname)
      }
      window.location.href = '/login'
    }
  }
}

// Export API instance and utilities
export default api
export { clearAuthData }
