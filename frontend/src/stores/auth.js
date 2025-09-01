import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/services/api'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const token = ref(localStorage.getItem('token'))
  const isLoading = ref(false)

  // Computed
  const isAuthenticated = computed(() => !!token.value && !!user.value)
  const isAdmin = computed(() => user.value?.role === 'admin')
  const isAuthor = computed(() => user.value?.role === 'author' || isAdmin.value)

  // Actions
  const initAuth = async () => {
    if (token.value) {
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
      const { token: authToken, user: userData } = response.data.data

      token.value = authToken
      user.value = userData
      localStorage.setItem('token', authToken)
      
      // Set default authorization header
      api.defaults.headers.common['Authorization'] = `Bearer ${authToken}`
      
      return { success: true }
    } catch (error) {
      console.error('Login failed:', error)
      return {
        success: false,
        message: error.response?.data?.error || 'Login failed'
      }
    } finally {
      isLoading.value = false
    }
  }

  const register = async (userData) => {
    isLoading.value = true
    try {
      const response = await api.post('/auth/register', userData)
      const { token: authToken, user: newUser } = response.data.data

      token.value = authToken
      user.value = newUser
      localStorage.setItem('token', authToken)
      
      // Set default authorization header
      api.defaults.headers.common['Authorization'] = `Bearer ${authToken}`
      
      return { success: true }
    } catch (error) {
      console.error('Registration failed:', error)
      return {
        success: false,
        message: error.response?.data?.error || 'Registration failed'
      }
    } finally {
      isLoading.value = false
    }
  }

  const getProfile = async () => {
    try {
      const response = await api.get('/auth/profile')
      user.value = response.data.data
      return response.data.data
    } catch (error) {
      console.error('Failed to get profile:', error)
      logout()
      throw error
    }
  }

  const logout = () => {
    user.value = null
    token.value = null
    localStorage.removeItem('token')
    delete api.defaults.headers.common['Authorization']
  }

  const updateProfile = async (profileData) => {
    isLoading.value = true
    try {
      const response = await api.put('/auth/profile', profileData)
      user.value = response.data.data
      return { success: true }
    } catch (error) {
      console.error('Profile update failed:', error)
      return {
        success: false,
        message: error.response?.data?.error || 'Profile update failed'
      }
    } finally {
      isLoading.value = false
    }
  }

  return {
    user,
    token,
    isLoading,
    isAuthenticated,
    isAdmin,
    isAuthor,
    initAuth,
    login,
    register,
    getProfile,
    logout,
    updateProfile
  }
})
