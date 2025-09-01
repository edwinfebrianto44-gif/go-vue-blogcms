import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api, { clearAuthData } from '@/services/api'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const accessToken = ref(localStorage.getItem('accessToken'))
  const refreshToken = ref(localStorage.getItem('refreshToken'))
  const isLoading = ref(false)

  // Computed
  const isAuthenticated = computed(() => !!accessToken.value && !!user.value)
  const isAdmin = computed(() => user.value?.role === 'admin')
  const isEditor = computed(() => user.value?.role === 'editor' || isAdmin.value)
  const isAuthor = computed(() => user.value?.role === 'author' || isEditor.value)

  // Load user from localStorage on store initialization
  const storedUser = localStorage.getItem('user')
  if (storedUser) {
    try {
      user.value = JSON.parse(storedUser)
    } catch (error) {
      console.error('Failed to parse stored user data:', error)
      localStorage.removeItem('user')
    }
  }

  // Actions
  const initAuth = async () => {
    if (accessToken.value) {
      try {
        await getProfile()
      } catch (error) {
        console.error('Failed to initialize auth:', error)
        logout()
      }
    }
  }

  const login = async (credentials) => {
    isLoading.value = true
    try {
      const response = await api.post('/auth/login', credentials)
      const { 
        access_token, 
        refresh_token, 
        user: userData 
      } = response.data.data

      // Store tokens and user data
      accessToken.value = access_token
      refreshToken.value = refresh_token
      user.value = userData

      localStorage.setItem('accessToken', access_token)
      localStorage.setItem('refreshToken', refresh_token)
      localStorage.setItem('user', JSON.stringify(userData))
      
      // Set default authorization header
      api.defaults.headers.common['Authorization'] = `Bearer ${access_token}`
      
      return { success: true, user: userData }
    } catch (error) {
      console.error('Login failed:', error)
      return {
        success: false,
        message: error.response?.data?.message || error.response?.data?.error || 'Login failed'
      }
    } finally {
      isLoading.value = false
    }
  }

  const register = async (userData) => {
    isLoading.value = true
    try {
      const response = await api.post('/auth/register', userData)
      const { 
        access_token, 
        refresh_token, 
        user: newUser 
      } = response.data.data

      // Store tokens and user data
      accessToken.value = access_token
      refreshToken.value = refresh_token
      user.value = newUser

      localStorage.setItem('accessToken', access_token)
      localStorage.setItem('refreshToken', refresh_token)
      localStorage.setItem('user', JSON.stringify(newUser))
      
      // Set default authorization header
      api.defaults.headers.common['Authorization'] = `Bearer ${access_token}`
      
      return { success: true, user: newUser }
    } catch (error) {
      console.error('Registration failed:', error)
      return {
        success: false,
        message: error.response?.data?.message || error.response?.data?.error || 'Registration failed'
      }
    } finally {
      isLoading.value = false
    }
  }

  const getProfile = async () => {
    try {
      const response = await api.get('/auth/profile')
      user.value = response.data.data
      localStorage.setItem('user', JSON.stringify(response.data.data))
      return response.data.data
    } catch (error) {
      console.error('Failed to get profile:', error)
      logout()
      throw error
    }
  }

  const logout = async () => {
    isLoading.value = true
    try {
      // Call logout endpoint if refresh token exists
      if (refreshToken.value) {
        await api.post('/auth/logout', {
          refresh_token: refreshToken.value
        })
      }
    } catch (error) {
      console.error('Logout API call failed:', error)
      // Continue with local logout even if API fails
    } finally {
      // Clear local state
      user.value = null
      accessToken.value = null
      refreshToken.value = null
      clearAuthData()
      isLoading.value = false
    }
  }

  const updateProfile = async (profileData) => {
    isLoading.value = true
    try {
      const response = await api.put('/auth/profile', profileData)
      user.value = response.data.data
      localStorage.setItem('user', JSON.stringify(response.data.data))
      return { success: true, user: response.data.data }
    } catch (error) {
      console.error('Profile update failed:', error)
      return {
        success: false,
        message: error.response?.data?.message || error.response?.data?.error || 'Profile update failed'
      }
    } finally {
      isLoading.value = false
    }
  }

  const refreshAccessToken = async () => {
    if (!refreshToken.value) {
      throw new Error('No refresh token available')
    }

    try {
      const response = await api.post('/auth/refresh', {
        refresh_token: refreshToken.value
      })

      const { access_token, refresh_token: newRefreshToken } = response.data.data
      
      accessToken.value = access_token
      localStorage.setItem('accessToken', access_token)
      
      if (newRefreshToken) {
        refreshToken.value = newRefreshToken
        localStorage.setItem('refreshToken', newRefreshToken)
      }

      api.defaults.headers.common['Authorization'] = `Bearer ${access_token}`
      
      return access_token
    } catch (error) {
      console.error('Token refresh failed:', error)
      logout()
      throw error
    }
  }

  // Permission helpers
  const hasPermission = (permission) => {
    if (!user.value) return false
    
    const rolePermissions = {
      admin: ['read', 'write', 'delete', 'manage_users', 'manage_categories'],
      editor: ['read', 'write', 'delete', 'manage_categories'],
      author: ['read', 'write']
    }
    
    return rolePermissions[user.value.role]?.includes(permission) || false
  }

  const canManagePost = (post) => {
    if (!user.value) return false
    if (user.value.role === 'admin') return true
    if (user.value.role === 'editor') return true
    if (user.value.role === 'author' && post.author_id === user.value.id) return true
    return false
  }

  return {
    user,
    accessToken,
    refreshToken,
    isLoading,
    isAuthenticated,
    isAdmin,
    isEditor,
    isAuthor,
    initAuth,
    login,
    register,
    getProfile,
    logout,
    updateProfile,
    refreshAccessToken,
    hasPermission,
    canManagePost
  }
})
