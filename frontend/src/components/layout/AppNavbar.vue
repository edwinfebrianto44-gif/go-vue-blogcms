<template>
  <nav class="bg-white shadow-sm border-b border-secondary-200 sticky top-0 z-50">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex justify-between items-center h-16">
        <!-- Logo -->
        <div class="flex items-center">
          <RouterLink to="/" class="flex items-center space-x-2">
            <div class="h-8 w-8 bg-primary-600 rounded-lg flex items-center justify-center">
              <span class="text-white font-bold text-lg">B</span>
            </div>
            <span class="text-xl font-bold text-gradient">BlogCMS</span>
          </RouterLink>
        </div>

        <!-- Desktop Navigation -->
        <div class="hidden md:block">
          <div class="flex items-center space-x-8">
            <RouterLink to="/" class="nav-link">Home</RouterLink>
            <RouterLink to="/posts" class="nav-link">Posts</RouterLink>
            
            <!-- Categories Dropdown -->
            <div class="relative" ref="categoriesDropdown">
              <button 
                @click="toggleCategoriesDropdown"
                class="nav-link flex items-center space-x-1"
              >
                <span>Categories</span>
                <ChevronDownIcon class="h-4 w-4" />
              </button>
              
              <div 
                v-show="showCategoriesDropdown"
                class="absolute top-full left-0 mt-1 w-48 bg-white border border-secondary-200 rounded-md shadow-lg z-50"
              >
                <div class="py-1">
                  <RouterLink
                    v-for="category in categories"
                    :key="category.id"
                    :to="`/categories/${category.slug}`"
                    class="block px-4 py-2 text-sm text-secondary-700 hover:bg-secondary-50"
                    @click="showCategoriesDropdown = false"
                  >
                    {{ category.name }}
                  </RouterLink>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- User Menu -->
        <div class="flex items-center space-x-4">
          <template v-if="authStore.isAuthenticated">
            <!-- Dashboard Link -->
            <RouterLink to="/dashboard" class="btn-outline btn-sm hidden md:inline-flex">
              Dashboard
            </RouterLink>
            
            <!-- User Dropdown -->
            <div class="relative" ref="userDropdown">
              <button
                @click="toggleUserDropdown"
                class="flex items-center space-x-2 p-2 rounded-md hover:bg-secondary-50"
              >
                <div class="h-8 w-8 bg-primary-100 rounded-full flex items-center justify-center">
                  <span class="text-primary-600 font-medium text-sm">
                    {{ authStore.user?.name?.charAt(0).toUpperCase() }}
                  </span>
                </div>
                <ChevronDownIcon class="h-4 w-4 text-secondary-600" />
              </button>
              
              <div 
                v-show="showUserDropdown"
                class="absolute top-full right-0 mt-1 w-48 bg-white border border-secondary-200 rounded-md shadow-lg z-50"
              >
                <div class="py-1">
                  <div class="px-4 py-2 text-sm text-secondary-500 border-b border-secondary-100">
                    {{ authStore.user?.email }}
                  </div>
                  <RouterLink
                    to="/dashboard"
                    class="block px-4 py-2 text-sm text-secondary-700 hover:bg-secondary-50 md:hidden"
                    @click="showUserDropdown = false"
                  >
                    Dashboard
                  </RouterLink>
                  <RouterLink
                    to="/dashboard/profile"
                    class="block px-4 py-2 text-sm text-secondary-700 hover:bg-secondary-50"
                    @click="showUserDropdown = false"
                  >
                    Profile Settings
                  </RouterLink>
                  <button
                    @click="handleLogout"
                    class="block w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50"
                  >
                    Logout
                  </button>
                </div>
              </div>
            </div>
          </template>
          
          <template v-else>
            <RouterLink to="/login" class="btn-outline btn-sm">Login</RouterLink>
            <RouterLink to="/register" class="btn-primary btn-sm">Sign Up</RouterLink>
          </template>

          <!-- Mobile Menu Button -->
          <button
            @click="toggleMobileMenu"
            class="md:hidden p-2 rounded-md text-secondary-600 hover:bg-secondary-50"
          >
            <Bars3Icon v-if="!showMobileMenu" class="h-6 w-6" />
            <XMarkIcon v-else class="h-6 w-6" />
          </button>
        </div>
      </div>

      <!-- Mobile Menu -->
      <div v-show="showMobileMenu" class="md:hidden py-4 border-t border-secondary-200">
        <div class="space-y-2">
          <RouterLink to="/" class="block py-2 text-base font-medium text-secondary-700" @click="showMobileMenu = false">
            Home
          </RouterLink>
          <RouterLink to="/posts" class="block py-2 text-base font-medium text-secondary-700" @click="showMobileMenu = false">
            Posts
          </RouterLink>
          
          <!-- Mobile Categories -->
          <div class="py-2">
            <div class="text-base font-medium text-secondary-700 mb-2">Categories</div>
            <div class="pl-4 space-y-1">
              <RouterLink
                v-for="category in categories"
                :key="category.id"
                :to="`/categories/${category.slug}`"
                class="block py-1 text-secondary-600"
                @click="showMobileMenu = false"
              >
                {{ category.name }}
              </RouterLink>
            </div>
          </div>
        </div>
      </div>
    </div>
  </nav>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import { ChevronDownIcon, Bars3Icon, XMarkIcon } from '@heroicons/vue/24/outline'
import { useAuthStore } from '@/stores/auth'
import { useCategoriesStore } from '@/stores/categories'

const router = useRouter()
const authStore = useAuthStore()
const categoriesStore = useCategoriesStore()

const showCategoriesDropdown = ref(false)
const showUserDropdown = ref(false)
const showMobileMenu = ref(false)
const categoriesDropdown = ref(null)
const userDropdown = ref(null)

const categories = ref([])

const toggleCategoriesDropdown = () => {
  showCategoriesDropdown.value = !showCategoriesDropdown.value
  showUserDropdown.value = false
}

const toggleUserDropdown = () => {
  showUserDropdown.value = !showUserDropdown.value
  showCategoriesDropdown.value = false
}

const toggleMobileMenu = () => {
  showMobileMenu.value = !showMobileMenu.value
}

const handleLogout = () => {
  authStore.logout()
  showUserDropdown.value = false
  router.push('/')
}

const handleClickOutside = (event) => {
  if (categoriesDropdown.value && !categoriesDropdown.value.contains(event.target)) {
    showCategoriesDropdown.value = false
  }
  if (userDropdown.value && !userDropdown.value.contains(event.target)) {
    showUserDropdown.value = false
  }
}

onMounted(async () => {
  document.addEventListener('click', handleClickOutside)
  
  // Fetch categories for navigation
  try {
    categories.value = await categoriesStore.fetchCategories()
  } catch (error) {
    console.error('Failed to fetch categories:', error)
  }
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>

<style scoped>
.nav-link {
  @apply text-secondary-700 hover:text-primary-600 px-3 py-2 rounded-md text-sm font-medium transition-colors;
}

.router-link-active.nav-link {
  @apply text-primary-600;
}
</style>
