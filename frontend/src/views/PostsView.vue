<template>
  <div class="min-h-screen bg-secondary-50">
    <!-- Header -->
    <div class="bg-white shadow-sm">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div class="text-center">
          <h1 class="text-3xl font-bold text-secondary-900 sm:text-4xl">All Posts</h1>
          <p class="mt-3 max-w-2xl mx-auto text-xl text-secondary-500">
            Discover amazing content from our community
          </p>
        </div>

        <!-- Search and Filters -->
        <div class="mt-8 max-w-3xl mx-auto">
          <div class="flex flex-col sm:flex-row gap-4">
            <!-- Search Input -->
            <div class="flex-1 relative">
              <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <MagnifyingGlassIcon class="h-5 w-5 text-secondary-400" />
              </div>
              <input
                v-model="searchQuery"
                type="text"
                placeholder="Search posts..."
                class="input pl-10"
                @keyup.enter="performSearch"
              />
            </div>

            <!-- Category Filter -->
            <div class="sm:w-48">
              <select v-model="selectedCategory" class="input" @change="performSearch">
                <option value="">All Categories</option>
                <option
                  v-for="category in categoriesStore.categories"
                  :key="category.id"
                  :value="category.id"
                >
                  {{ category.name }}
                </option>
              </select>
            </div>

            <!-- Sort -->
            <div class="sm:w-48">
              <select v-model="sortBy" class="input" @change="performSearch">
                <option value="created_at">Latest First</option>
                <option value="-created_at">Oldest First</option>
                <option value="title">Title A-Z</option>
                <option value="-title">Title Z-A</option>
                <option value="relevance">Most Relevant</option>
              </select>
            </div>

            <!-- Search Button -->
            <button
              @click="performSearch"
              class="btn-primary"
              :disabled="postsStore.isLoading"
            >
              <MagnifyingGlassIcon class="h-5 w-5" />
              <span class="sr-only">Search</span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Content -->
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Loading State -->
      <div v-if="postsStore.isLoading && posts.length === 0" class="space-y-8">
        <div v-for="i in 6" :key="i" class="animate-pulse">
          <div class="bg-white rounded-lg shadow-sm p-6">
            <div class="h-4 bg-secondary-200 rounded w-3/4 mb-3"></div>
            <div class="h-3 bg-secondary-200 rounded w-1/2 mb-4"></div>
            <div class="space-y-2">
              <div class="h-3 bg-secondary-200 rounded"></div>
              <div class="h-3 bg-secondary-200 rounded w-5/6"></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Posts Grid -->
      <div v-else-if="posts.length > 0" class="space-y-8">
        <!-- Results Info -->
        <div class="flex items-center justify-between">
          <p class="text-sm text-secondary-600">
            Showing {{ ((meta.page - 1) * meta.limit) + 1 }} to 
            {{ Math.min(meta.page * meta.limit, meta.total) }} of 
            {{ meta.total }} results
            <span v-if="searchQuery" class="font-medium">for "{{ searchQuery }}"</span>
          </p>
          
          <div class="text-sm text-secondary-500">
            Page {{ meta.page }} of {{ meta.total_pages }}
          </div>
        </div>

        <!-- Posts List -->
        <div class="grid gap-8 lg:grid-cols-2">
          <PostCard
            v-for="post in posts"
            :key="post.id"
            :post="post"
            class="h-full"
          />
        </div>

        <!-- Pagination -->
        <div v-if="meta.total_pages > 1" class="flex justify-center">
          <nav class="flex items-center space-x-2">
            <!-- Previous Page -->
            <button
              @click="goToPage(meta.page - 1)"
              :disabled="meta.page <= 1 || postsStore.isLoading"
              class="px-3 py-2 text-sm font-medium text-secondary-500 bg-white border border-secondary-300 rounded-md hover:bg-secondary-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Previous
            </button>

            <!-- Page Numbers -->
            <template v-for="page in getPageNumbers()" :key="page">
              <button
                v-if="page !== '...'"
                @click="goToPage(page)"
                :class="[
                  'px-3 py-2 text-sm font-medium rounded-md',
                  page === meta.page
                    ? 'text-white bg-primary-600 border border-primary-600'
                    : 'text-secondary-500 bg-white border border-secondary-300 hover:bg-secondary-50'
                ]"
                :disabled="postsStore.isLoading"
              >
                {{ page }}
              </button>
              <span v-else class="px-3 py-2 text-sm font-medium text-secondary-500">...</span>
            </template>

            <!-- Next Page -->
            <button
              @click="goToPage(meta.page + 1)"
              :disabled="meta.page >= meta.total_pages || postsStore.isLoading"
              class="px-3 py-2 text-sm font-medium text-secondary-500 bg-white border border-secondary-300 rounded-md hover:bg-secondary-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Next
            </button>
          </nav>
        </div>
      </div>

      <!-- Empty State -->
      <div v-else class="text-center py-12">
        <div class="max-w-md mx-auto">
          <div class="h-24 w-24 mx-auto mb-4 bg-secondary-100 rounded-full flex items-center justify-center">
            <DocumentTextIcon class="h-12 w-12 text-secondary-400" />
          </div>
          <h3 class="text-lg font-medium text-secondary-900 mb-2">
            {{ searchQuery ? 'No posts found' : 'No posts available' }}
          </h3>
          <p class="text-secondary-500">
            {{ 
              searchQuery 
                ? `Try adjusting your search criteria or browse all posts.`
                : 'Be the first to create a post!'
            }}
          </p>
          <div class="mt-6 space-x-4">
            <button
              v-if="searchQuery"
              @click="clearSearch"
              class="btn-outline"
            >
              Clear Search
            </button>
            <RouterLink
              v-if="authStore.isAuthenticated && authStore.isAuthor"
              to="/dashboard/posts/create"
              class="btn-primary"
            >
              Create Post
            </RouterLink>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { MagnifyingGlassIcon, DocumentTextIcon } from '@heroicons/vue/24/outline'
import { usePostsStore } from '@/stores/posts'
import { useCategoriesStore } from '@/stores/categories'
import { useAuthStore } from '@/stores/auth'
import { useSEO, createBreadcrumbJsonLd } from '@/composables/useSEO'
import PostCard from '@/components/PostCard.vue'

const route = useRoute()
const router = useRouter()
const postsStore = usePostsStore()
const categoriesStore = useCategoriesStore()
const authStore = useAuthStore()

// Reactive data
const searchQuery = ref(route.query.q || '')
const selectedCategory = ref(route.query.category_id || '')
const sortBy = ref(route.query.sort || 'created_at')
const currentPage = ref(parseInt(route.query.page) || 1)

// Computed
const posts = computed(() => postsStore.posts)
const meta = computed(() => postsStore.meta)

// SEO Configuration
const seoTitle = computed(() => {
  if (searchQuery.value) return `Search Results for "${searchQuery.value}"`
  if (selectedCategory.value) {
    const category = categoriesStore.categories.find(c => c.id === selectedCategory.value)
    return category ? `Posts in ${category.name}` : 'All Posts'
  }
  return 'All Posts'
})

const seoDescription = computed(() => {
  if (searchQuery.value) return `Search results for "${searchQuery.value}" - Find relevant articles and insights.`
  if (selectedCategory.value) {
    const category = categoriesStore.categories.find(c => c.id === selectedCategory.value)
    return category 
      ? `Browse all posts in the ${category.name} category. ${category.description || ''}`
      : 'Discover amazing content from our community of writers.'
  }
  return 'Discover amazing content from our community of writers. Browse all posts and find your next great read.'
})

useSEO({
  title: seoTitle.value,
  description: seoDescription.value,
  url: '/posts',
  type: 'website',
  tags: ['blog', 'posts', 'articles', 'reading', 'community']
})

// Methods
const performSearch = async () => {
  currentPage.value = 1 // Reset to first page on new search
  await fetchPosts()
  updateURL()
}

const fetchPosts = async () => {
  const params = {
    page: currentPage.value,
    limit: 12,
    q: searchQuery.value || undefined,
    category_id: selectedCategory.value || undefined,
    sort: sortBy.value || undefined,
    status: 'published' // Only show published posts
  }

  try {
    await postsStore.searchPosts(params)
  } catch (error) {
    console.error('Failed to fetch posts:', error)
    if (window.toast) {
      window.toast.error('Error', 'Failed to load posts. Please try again.')
    }
  }
}

const goToPage = async (page) => {
  if (page < 1 || page > meta.value.total_pages) return
  
  currentPage.value = page
  await fetchPosts()
  updateURL()
  
  // Scroll to top
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

const getPageNumbers = () => {
  const pages = []
  const current = meta.value.page
  const total = meta.value.total_pages
  
  if (total <= 7) {
    // Show all pages if total is small
    for (let i = 1; i <= total; i++) {
      pages.push(i)
    }
  } else {
    // Show first page
    pages.push(1)
    
    if (current <= 4) {
      // Show pages 2-5 and ellipsis
      for (let i = 2; i <= 5; i++) {
        pages.push(i)
      }
      pages.push('...')
    } else if (current >= total - 3) {
      // Show ellipsis and last 4 pages
      pages.push('...')
      for (let i = total - 4; i < total; i++) {
        pages.push(i)
      }
    } else {
      // Show ellipsis, current area, ellipsis
      pages.push('...')
      for (let i = current - 1; i <= current + 1; i++) {
        pages.push(i)
      }
      pages.push('...')
    }
    
    // Show last page
    if (total > 1) pages.push(total)
  }
  
  return pages
}

const clearSearch = () => {
  searchQuery.value = ''
  selectedCategory.value = ''
  sortBy.value = 'created_at'
  currentPage.value = 1
  performSearch()
}

const updateURL = () => {
  const query = {}
  
  if (searchQuery.value) query.q = searchQuery.value
  if (selectedCategory.value) query.category_id = selectedCategory.value
  if (sortBy.value !== 'created_at') query.sort = sortBy.value
  if (currentPage.value > 1) query.page = currentPage.value
  
  router.replace({ query })
}

// Watch for route changes
watch(() => route.query, (newQuery) => {
  searchQuery.value = newQuery.q || ''
  selectedCategory.value = newQuery.category_id || ''
  sortBy.value = newQuery.sort || 'created_at'
  currentPage.value = parseInt(newQuery.page) || 1
}, { immediate: true })

// Lifecycle
onMounted(async () => {
  // Load categories for filter
  try {
    await categoriesStore.fetchCategories({ limit: 100 })
  } catch (error) {
    console.error('Failed to load categories:', error)
  }
  
  // Load posts
  await fetchPosts()
  
  // Add breadcrumb structured data
  const breadcrumbSchema = createBreadcrumbJsonLd([
    { name: 'Home', url: '/' },
    { name: 'Posts', url: '/posts' }
  ])
  document.head.appendChild(breadcrumbSchema)
})
</script>
