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
        <h2 class="text-3xl font-bold text-secondary-900">Create your account</h2>
        <p class="mt-2 text-secondary-600">
          Already have an account?
          <RouterLink to="/login" class="text-primary-600 hover:text-primary-500 font-medium">
            Sign in here
          </RouterLink>
        </p>
      </div>

      <!-- Register Form -->
      <form @submit.prevent="handleRegister" class="mt-8 space-y-6">
        <div class="space-y-4">
          <!-- Name -->
          <div>
            <label for="name" class="label">Full Name</label>
            <input
              id="name"
              v-model="form.name"
              type="text"
              required
              class="input"
              :class="{ 'border-red-300 focus:border-red-500 focus:ring-red-500': errors.name }"
              placeholder="Enter your full name"
            />
            <p v-if="errors.name" class="text-red-600 text-sm mt-1">{{ errors.name }}</p>
          </div>

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
                placeholder="Create a password"
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
            <div class="mt-1">
              <div class="flex space-x-1">
                <div
                  v-for="(req, index) in passwordRequirements"
                  :key="index"
                  class="flex-1 h-1 rounded"
                  :class="req.met ? 'bg-green-500' : 'bg-secondary-200'"
                ></div>
              </div>
              <p class="text-xs text-secondary-500 mt-1">
                Password must be at least 8 characters with uppercase, lowercase, number
              </p>
            </div>
          </div>

          <!-- Confirm Password -->
          <div>
            <label for="confirmPassword" class="label">Confirm Password</label>
            <div class="relative">
              <input
                id="confirmPassword"
                v-model="form.confirmPassword"
                :type="showConfirmPassword ? 'text' : 'password'"
                required
                class="input pr-10"
                :class="{ 'border-red-300 focus:border-red-500 focus:ring-red-500': errors.confirmPassword }"
                placeholder="Confirm your password"
              />
              <button
                type="button"
                @click="showConfirmPassword = !showConfirmPassword"
                class="absolute inset-y-0 right-0 pr-3 flex items-center"
              >
                <EyeIcon v-if="!showConfirmPassword" class="h-5 w-5 text-secondary-400" />
                <EyeSlashIcon v-else class="h-5 w-5 text-secondary-400" />
              </button>
            </div>
            <p v-if="errors.confirmPassword" class="text-red-600 text-sm mt-1">{{ errors.confirmPassword }}</p>
          </div>
        </div>

        <!-- Terms and Conditions -->
        <div class="flex items-start">
          <div class="flex items-center h-5">
            <input
              id="terms"
              v-model="form.terms"
              type="checkbox"
              class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-secondary-300 rounded"
              :class="{ 'border-red-300': errors.terms }"
            />
          </div>
          <div class="ml-3 text-sm">
            <label for="terms" class="text-secondary-700">
              I agree to the
              <a href="#" class="text-primary-600 hover:text-primary-500">Terms and Conditions</a>
              and
              <a href="#" class="text-primary-600 hover:text-primary-500">Privacy Policy</a>
            </label>
            <p v-if="errors.terms" class="text-red-600 text-sm mt-1">{{ errors.terms }}</p>
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
            :disabled="authStore.isLoading || !isFormValid"
            class="btn-primary w-full btn-lg relative"
            :class="{ 'opacity-50 cursor-not-allowed': !isFormValid }"
          >
            <span v-if="!authStore.isLoading">Create Account</span>
            <span v-else class="flex items-center justify-center">
              <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Creating Account...
            </span>
          </button>
        </div>

        <!-- Divider -->
        <div class="relative">
          <div class="absolute inset-0 flex items-center">
            <div class="w-full border-t border-secondary-300" />
          </div>
          <div class="relative flex justify-center text-sm">
            <span class="px-2 bg-secondary-50 text-secondary-500">Already have an account?</span>
          </div>
        </div>

        <!-- Login Link -->
        <div class="text-center">
          <RouterLink
            to="/login"
            class="btn-outline w-full"
          >
            Sign in instead
          </RouterLink>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { EyeIcon, EyeSlashIcon } from '@heroicons/vue/24/outline'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const form = reactive({
  name: '',
  email: '',
  password: '',
  confirmPassword: '',
  terms: false
})

const errors = ref({})
const errorMessage = ref('')
const showPassword = ref(false)
const showConfirmPassword = ref(false)

const passwordRequirements = computed(() => [
  { met: form.password.length >= 8 },
  { met: /[a-z]/.test(form.password) },
  { met: /[A-Z]/.test(form.password) },
  { met: /\d/.test(form.password) }
])

const isFormValid = computed(() => {
  return form.name && form.email && form.password && form.confirmPassword && 
         form.password === form.confirmPassword && form.terms &&
         passwordRequirements.value.every(req => req.met)
})

const validateForm = () => {
  errors.value = {}
  
  if (!form.name.trim()) {
    errors.value.name = 'Full name is required'
  } else if (form.name.trim().length < 2) {
    errors.value.name = 'Name must be at least 2 characters'
  }
  
  if (!form.email) {
    errors.value.email = 'Email is required'
  } else if (!/\S+@\S+\.\S+/.test(form.email)) {
    errors.value.email = 'Please enter a valid email'
  }
  
  if (!form.password) {
    errors.value.password = 'Password is required'
  } else if (form.password.length < 8) {
    errors.value.password = 'Password must be at least 8 characters'
  } else if (!/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/.test(form.password)) {
    errors.value.password = 'Password must contain uppercase, lowercase and number'
  }
  
  if (!form.confirmPassword) {
    errors.value.confirmPassword = 'Please confirm your password'
  } else if (form.password !== form.confirmPassword) {
    errors.value.confirmPassword = 'Passwords do not match'
  }
  
  if (!form.terms) {
    errors.value.terms = 'You must agree to the terms and conditions'
  }
  
  return Object.keys(errors.value).length === 0
}

const handleRegister = async () => {
  errorMessage.value = ''
  
  if (!validateForm()) {
    return
  }
  
  const result = await authStore.register({
    name: form.name.trim(),
    email: form.email,
    password: form.password
  })
  
  if (result.success) {
    if (window.toast) {
      window.toast.success('Account created!', 'Welcome to BlogCMS. You can now start creating content.')
    }
    
    router.push('/dashboard')
  } else {
    errorMessage.value = result.message
  }
}
</script>
