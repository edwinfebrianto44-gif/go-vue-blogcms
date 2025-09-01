<template>
  <div class="min-h-screen flex items-center justify-center bg-secondary-50 py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8">
      <!-- Header -->
      <div class="text-center">
        <RouterLink to="/" class="flex items-center justify-center space-x-2 mb-6">
          <div class="h-10 w-10 bg-primary-600 rounded-lg flex items-center justify-center">
            <span class="text-white font-bold text-xl">B</span>
          </div>
          <span class="text-2xl font-bold text-gradient">BlogCMS</span>
        </RouterLink>
        <h2 class="text-3xl font-bold text-secondary-900">Sign in to your account</h2>
        <p class="mt-2 text-secondary-600">
          Or
          <RouterLink to="/register" class="text-primary-600 hover:text-primary-500 font-medium">
            create a new account
          </RouterLink>
        </p>
      </div>

      <!-- Login Form -->
      <form @submit.prevent="handleLogin" class="mt-8 space-y-6">
        <div class="space-y-4">
          <!-- Email -->
          <div>
            <label for="email" class="label">Email address</label>
            <input
              id="email"
              v-model="form.email"
              type="email"
              required
              class="input"
              :class="{ 'border-red-300 focus:border-red-500 focus:ring-red-500': errors.email }"
              placeholder="Enter your email"
            />
            <p v-if="errors.email" class="text-red-600 text-sm mt-1">{{ errors.email }}</p>
          </div>

          <!-- Password -->
          <div>
            <label for="password" class="label">Password</label>
            <div class="relative">
              <input
                id="password"
                v-model="form.password"
                :type="showPassword ? 'text' : 'password'"
                required
                class="input pr-10"
                :class="{ 'border-red-300 focus:border-red-500 focus:ring-red-500': errors.password }"
                placeholder="Enter your password"
              />
              <button
                type="button"
                @click="showPassword = !showPassword"
                class="absolute inset-y-0 right-0 pr-3 flex items-center"
              >
                <EyeIcon v-if="!showPassword" class="h-5 w-5 text-secondary-400" />
                <EyeSlashIcon v-else class="h-5 w-5 text-secondary-400" />
              </button>
            </div>
            <p v-if="errors.password" class="text-red-600 text-sm mt-1">{{ errors.password }}</p>
          </div>
        </div>

        <!-- Remember me & Forgot password -->
        <div class="flex items-center justify-between">
          <div class="flex items-center">
            <input
              id="remember-me"
              v-model="form.remember"
              type="checkbox"
              class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-secondary-300 rounded"
            />
            <label for="remember-me" class="ml-2 block text-sm text-secondary-700">
              Remember me
            </label>
          </div>

          <div class="text-sm">
            <a href="#" class="text-primary-600 hover:text-primary-500">
              Forgot your password?
            </a>
          </div>
        </div>

        <!-- Error Message -->
        <div v-if="errorMessage" class="bg-red-50 border border-red-200 rounded-md p-3">
          <p class="text-red-600 text-sm">{{ errorMessage }}</p>
        </div>

        <!-- Submit Button -->
        <div>
          <button
            type="submit"
            :disabled="authStore.isLoading"
            class="btn-primary w-full btn-lg relative"
          >
            <span v-if="!authStore.isLoading">Sign in</span>
            <span v-else class="flex items-center justify-center">
              <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Signing in...
            </span>
          </button>
        </div>

        <!-- Divider -->
        <div class="relative">
          <div class="absolute inset-0 flex items-center">
            <div class="w-full border-t border-secondary-300" />
          </div>
          <div class="relative flex justify-center text-sm">
            <span class="px-2 bg-secondary-50 text-secondary-500">New to BlogCMS?</span>
          </div>
        </div>

        <!-- Register Link -->
        <div class="text-center">
          <RouterLink
            to="/register"
            class="btn-outline w-full"
          >
            Create an account
          </RouterLink>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { RouterLink, useRouter, useRoute } from 'vue-router'
import { EyeIcon, EyeSlashIcon } from '@heroicons/vue/24/outline'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const form = reactive({
  email: '',
  password: '',
  remember: false
})

const errors = ref({})
const errorMessage = ref('')
const showPassword = ref(false)

const validateForm = () => {
  errors.value = {}
  
  if (!form.email) {
    errors.value.email = 'Email is required'
  } else if (!/\S+@\S+\.\S+/.test(form.email)) {
    errors.value.email = 'Please enter a valid email'
  }
  
  if (!form.password) {
    errors.value.password = 'Password is required'
  } else if (form.password.length < 6) {
    errors.value.password = 'Password must be at least 6 characters'
  }
  
  return Object.keys(errors.value).length === 0
}

const handleLogin = async () => {
  errorMessage.value = ''
  
  if (!validateForm()) {
    return
  }
  
  const result = await authStore.login({
    email: form.email,
    password: form.password
  })
  
  if (result.success) {
    if (window.toast) {
      window.toast.success('Welcome back!', 'You have been logged in successfully.')
    }
    
    // Redirect to intended page or dashboard
    const redirect = route.query.redirect || '/dashboard'
    router.push(redirect)
  } else {
    errorMessage.value = result.message
  }
}
</script>
