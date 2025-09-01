<template>
  <header class="bg-white shadow-sm border-b border-secondary-200">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex justify-between items-center h-16">
        <!-- Logo and Navigation -->
        <div class="flex items-center space-x-8">
          <RouterLink to="/dashboard" class="flex items-center space-x-2">
            <div class="h-8 w-8 bg-primary-600 rounded-lg flex items-center justify-center">
              <span class="text-white font-bold">B</span>
            </div>
            <span class="text-xl font-bold text-gradient">BlogCMS</span>
          </RouterLink>

          <!-- Navigation Menu -->
          <nav class="hidden md:flex space-x-6">
            <RouterLink
              to="/dashboard"
              class="nav-link"
              :class="{ 'text-primary-600': $route.path === '/dashboard' }"
            >
              Dashboard
            </RouterLink>
            <RouterLink
              to="/dashboard/posts"
              class="nav-link"
              :class="{ 'text-primary-600': $route.path.startsWith('/dashboard/posts') }"
            >
              Posts
            </RouterLink>
            <RouterLink
              to="/dashboard/categories"
              class="nav-link"
              :class="{ 'text-primary-600': $route.path.startsWith('/dashboard/categories') }"
            >
              Categories
            </RouterLink>
            <RouterLink
              v-if="authStore.user?.role === 'admin'"
              to="/dashboard/comments"
              class="nav-link"
              :class="{ 'text-primary-600': $route.path.startsWith('/dashboard/comments') }"
            >
              Comments
            </RouterLink>
          </nav>
        </div>

        <!-- Right side actions -->
        <div class="flex items-center space-x-4">
          <!-- View Site -->
          <RouterLink
            to="/"
            class="text-secondary-600 hover:text-secondary-900 text-sm font-medium"
          >
            View Site
          </RouterLink>

          <!-- Create Post Button -->
          <RouterLink
            to="/dashboard/posts/create"
            class="btn-primary btn-sm"
          >
            <PlusIcon class="h-4 w-4 mr-1" />
            New Post
          </RouterLink>

          <!-- Notifications -->
          <div class="relative">
            <button
              @click="showNotifications = !showNotifications"
              class="p-2 text-secondary-600 hover:text-secondary-900 relative"
            >
              <BellIcon class="h-6 w-6" />
              <span
                v-if="unreadCount > 0"
                class="absolute -top-1 -right-1 h-4 w-4 bg-red-500 text-white rounded-full text-xs flex items-center justify-center"
              >
                {{ unreadCount > 9 ? '9+' : unreadCount }}
              </span>
            </button>

            <!-- Notifications Dropdown -->
            <div
              v-if="showNotifications"
              v-click-outside="() => showNotifications = false"
              class="absolute right-0 mt-2 w-80 bg-white rounded-lg shadow-lg border border-secondary-200 z-50"
            >
              <div class="p-4 border-b border-secondary-200">
                <h3 class="font-semibold text-secondary-900">Notifications</h3>
              </div>
              <div class="max-h-96 overflow-y-auto">
                <div v-if="notifications.length === 0" class="p-4 text-center">
                  <p class="text-secondary-500">No notifications</p>
                </div>
                <div v-else>
                  <div
                    v-for="notification in notifications"
                    :key="notification.id"
                    class="p-4 border-b border-secondary-100 hover:bg-secondary-50"
                    :class="{ 'bg-blue-50': !notification.read }"
                  >
                    <p class="text-sm text-secondary-900">{{ notification.message }}</p>
                    <p class="text-xs text-secondary-500 mt-1">{{ formatDate(notification.created_at) }}</p>
                  </div>
                </div>
              </div>
              <div class="p-4 border-t border-secondary-200">
                <button
                  @click="markAllAsRead"
                  class="text-primary-600 hover:text-primary-700 text-sm font-medium w-full text-center"
                >
                  Mark all as read
                </button>
              </div>
            </div>
          </div>

          <!-- User Menu -->
          <div class="relative">
            <button
              @click="showUserMenu = !showUserMenu"
              class="flex items-center space-x-2 p-2 rounded-lg hover:bg-secondary-100"
            >
              <div class="h-8 w-8 bg-primary-100 rounded-full flex items-center justify-center">
                <span class="text-primary-700 font-medium text-sm">
                  {{ authStore.user?.name?.charAt(0)?.toUpperCase() }}
                </span>
              </div>
              <ChevronDownIcon class="h-4 w-4 text-secondary-600" />
            </button>

            <!-- User Menu Dropdown -->
            <div
              v-if="showUserMenu"
              v-click-outside="() => showUserMenu = false"
              class="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg border border-secondary-200 z-50"
            >
              <div class="p-3 border-b border-secondary-200">
                <p class="font-medium text-secondary-900">{{ authStore.user?.name }}</p>
                <p class="text-sm text-secondary-500">{{ authStore.user?.email }}</p>
              </div>
              <div class="py-2">
                <RouterLink
                  to="/dashboard/profile"
                  class="block px-4 py-2 text-sm text-secondary-700 hover:bg-secondary-100"
                >
                  <UserIcon class="inline h-4 w-4 mr-2" />
                  Profile
                </RouterLink>
                <RouterLink
                  to="/dashboard/settings"
                  class="block px-4 py-2 text-sm text-secondary-700 hover:bg-secondary-100"
                >
                  <CogIcon class="inline h-4 w-4 mr-2" />
                  Settings
                </RouterLink>
                <div class="border-t border-secondary-200 mt-2 pt-2">
                  <button
                    @click="handleLogout"
                    class="block w-full text-left px-4 py-2 text-sm text-red-600 hover:bg-red-50"
                  >
                    <ArrowLeftOnRectangleIcon class="inline h-4 w-4 mr-2" />
                    Sign out
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Mobile menu button -->
          <button
            @click="showMobileMenu = !showMobileMenu"
            class="md:hidden p-2 text-secondary-600 hover:text-secondary-900"
          >
            <Bars3Icon v-if="!showMobileMenu" class="h-6 w-6" />
            <XMarkIcon v-else class="h-6 w-6" />
          </button>
        </div>
      </div>

      <!-- Mobile Menu -->
      <div
        v-if="showMobileMenu"
        class="md:hidden border-t border-secondary-200 py-4"
      >
        <nav class="space-y-2">
          <RouterLink
            to="/dashboard"
            class="block py-2 text-secondary-700 hover:text-primary-600"
            @click="showMobileMenu = false"
          >
            Dashboard
          </RouterLink>
          <RouterLink
            to="/dashboard/posts"
            class="block py-2 text-secondary-700 hover:text-primary-600"
            @click="showMobileMenu = false"
          >
            Posts
          </RouterLink>
          <RouterLink
            to="/dashboard/categories"
            class="block py-2 text-secondary-700 hover:text-primary-600"
            @click="showMobileMenu = false"
          >
            Categories
          </RouterLink>
          <RouterLink
            v-if="authStore.user?.role === 'admin'"
            to="/dashboard/comments"
            class="block py-2 text-secondary-700 hover:text-primary-600"
            @click="showMobileMenu = false"
          >
            Comments
          </RouterLink>
        </nav>
      </div>
    </div>
  </header>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { RouterLink, useRouter } from 'vue-router'
import {
  PlusIcon,
  BellIcon,
  ChevronDownIcon,
  UserIcon,
  CogIcon,
  ArrowLeftOnRectangleIcon,
  Bars3Icon,
  XMarkIcon
} from '@heroicons/vue/24/outline'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const showUserMenu = ref(false)
const showNotifications = ref(false)
const showMobileMenu = ref(false)
const notifications = ref([])

const unreadCount = computed(() => {
  return notifications.value.filter(n => !n.read).length
})

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const handleLogout = async () => {
  await authStore.logout()
  if (window.toast) {
    window.toast.success('Signed out successfully')
  }
  router.push('/login')
}

const markAllAsRead = () => {
  notifications.value.forEach(n => n.read = true)
  showNotifications.value = false
}

// Mock notifications - in a real app, these would come from your API
const loadNotifications = () => {
  notifications.value = [
    {
      id: 1,
      message: 'New comment on "Getting Started with Vue 3"',
      created_at: new Date(Date.now() - 1000 * 60 * 30), // 30 minutes ago
      read: false
    },
    {
      id: 2,
      message: 'Your post "Advanced JavaScript Patterns" was published',
      created_at: new Date(Date.now() - 1000 * 60 * 60 * 2), // 2 hours ago
      read: false
    },
    {
      id: 3,
      message: 'System maintenance scheduled for tonight',
      created_at: new Date(Date.now() - 1000 * 60 * 60 * 24), // 1 day ago
      read: true
    }
  ]
}

// Click outside directive
const vClickOutside = {
  beforeMount(el, binding) {
    el.clickOutsideEvent = function(event) {
      if (!(el === event.target || el.contains(event.target))) {
        binding.value(event)
      }
    }
    document.body.addEventListener('click', el.clickOutsideEvent)
  },
  unmounted(el) {
    document.body.removeEventListener('click', el.clickOutsideEvent)
  }
}

onMounted(() => {
  loadNotifications()
})
</script>

<style scoped>
.nav-link {
  @apply text-secondary-600 hover:text-secondary-900 font-medium text-sm transition-colors;
}
</style>
