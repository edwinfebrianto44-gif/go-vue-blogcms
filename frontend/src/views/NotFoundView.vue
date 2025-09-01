<template>
  <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
    <!-- Page Header -->
    <div class="text-center mb-12">
      <h1 class="text-4xl sm:text-5xl font-bold text-secondary-900 mb-4">
        404 - Page Not Found
      </h1>
      <p class="text-xl text-secondary-600 mb-8">
        Sorry, the page you're looking for doesn't exist or has been moved.
      </p>
      
      <!-- Illustration -->
      <div class="mb-8">
        <div class="mx-auto w-64 h-64 bg-secondary-100 rounded-full flex items-center justify-center">
          <ExclamationTriangleIcon class="h-24 w-24 text-secondary-400" />
        </div>
      </div>
      
      <!-- Action Buttons -->
      <div class="flex flex-col sm:flex-row items-center justify-center gap-4">
        <RouterLink
          to="/"
          class="btn-primary"
        >
          <HomeIcon class="h-5 w-5 mr-2" />
          Back to Home
        </RouterLink>
        
        <button
          @click="goBack"
          class="btn-outline"
        >
          <ArrowLeftIcon class="h-5 w-5 mr-2" />
          Go Back
        </button>
      </div>
    </div>

    <!-- Helpful Links -->
    <div class="mt-16">
      <h2 class="text-2xl font-bold text-secondary-900 text-center mb-8">
        You might be looking for:
      </h2>
      
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <RouterLink
          to="/"
          class="block p-6 bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow"
        >
          <div class="text-center">
            <div class="mx-auto w-12 h-12 bg-primary-100 rounded-lg flex items-center justify-center mb-4">
              <HomeIcon class="h-6 w-6 text-primary-600" />
            </div>
            <h3 class="text-lg font-medium text-secondary-900 mb-2">Home Page</h3>
            <p class="text-secondary-600">Browse the latest blog posts and featured content.</p>
          </div>
        </RouterLink>
        
        <RouterLink
          to="/posts"
          class="block p-6 bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow"
        >
          <div class="text-center">
            <div class="mx-auto w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center mb-4">
              <DocumentTextIcon class="h-6 w-6 text-green-600" />
            </div>
            <h3 class="text-lg font-medium text-secondary-900 mb-2">All Posts</h3>
            <p class="text-secondary-600">Explore all published blog posts and articles.</p>
          </div>
        </RouterLink>
        
        <RouterLink
          to="/dashboard"
          v-if="authStore.isAuthenticated"
          class="block p-6 bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow"
        >
          <div class="text-center">
            <div class="mx-auto w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center mb-4">
              <Cog6ToothIcon class="h-6 w-6 text-purple-600" />
            </div>
            <h3 class="text-lg font-medium text-secondary-900 mb-2">Dashboard</h3>
            <p class="text-secondary-600">Manage your posts and account settings.</p>
          </div>
        </RouterLink>
        
        <RouterLink
          to="/login"
          v-else
          class="block p-6 bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow"
        >
          <div class="text-center">
            <div class="mx-auto w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center mb-4">
              <UserCircleIcon class="h-6 w-6 text-blue-600" />
            </div>
            <h3 class="text-lg font-medium text-secondary-900 mb-2">Sign In</h3>
            <p class="text-secondary-600">Access your account and dashboard.</p>
          </div>
        </RouterLink>
      </div>
    </div>
  </div>
</template>

<script setup>
import { RouterLink, useRouter } from 'vue-router'
import {
  ExclamationTriangleIcon,
  HomeIcon,
  ArrowLeftIcon,
  DocumentTextIcon,
  Cog6ToothIcon,
  UserCircleIcon
} from '@heroicons/vue/24/outline'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const goBack = () => {
  if (window.history.length > 1) {
    router.go(-1)
  } else {
    router.push('/')
  }
}
</script>
