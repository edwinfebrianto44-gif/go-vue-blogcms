<template>
  <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
    <!-- Loading State -->
    <div v-if="categoriesStore.isLoading" class="text-center py-12">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600 mx-auto"></div>
      <p class="text-secondary-600 mt-4">Loading category...</p>
    </div>

    <!-- Category Not Found -->
    <div v-else-if="!category" class="text-center py-12">
      <FolderIcon class="mx-auto h-16 w-16 text-secondary-400 mb-4" />
      <h1 class="text-2xl font-bold text-secondary-900 mb-2">Category not found</h1>
      <p class="text-secondary-600 mb-6">The category you're looking for doesn't exist.</p>
      <RouterLink to="/" class="btn-primary">
        Back to Home
      </RouterLink>
    </div>

    <!-- Category Content -->
    <div v-else>
      <!-- Page Header -->
      <div class="mb-8">
        <div class="flex items-center space-x-4 text-sm text-secondary-600 mb-4">
          <RouterLink to="/" class="hover:text-primary-600">Home</RouterLink>
          <ChevronRightIcon class="h-4 w-4" />
          <span class="text-secondary-900">{{ category.name }}</span>
        </div>
        
        <div class="flex items-center mb-6">
          <div class="h-12 w-12 bg-primary-100 rounded-lg flex items-center justify-center mr-4">
            <FolderIcon class="h-6 w-6 text-primary-600" />
          </div>
          <div>
            <h1 class="text-3xl font-bold text-secondary-900">{{ category.name }}</h1>
            <p class="text-secondary-600 mt-1">{{ categoryPosts.length }} posts in this category</p>
          </div>
        </div>
        
        <div v-if="category.description" class="prose prose-lg max-w-none mb-8">
          <p class="text-secondary-700">{{ category.description }}</p>
        </div>
      </div>

      <!-- Search -->
      <div class="bg-white rounded-lg shadow-sm p-6 mb-8">
        <div class="relative max-w-md">
          <MagnifyingGlassIcon class="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-secondary-400" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search posts in this category..."
            class="input pl-10"
            @input="debouncedSearch"
          />
        </div>
      </div>

      <!-- Posts -->
      <div v-if="filteredPosts.length === 0" class="text-center py-12">
        <DocumentTextIcon class="mx-auto h-16 w-16 text-secondary-400 mb-4" />
        <h2 class="text-2xl font-bold text-secondary-900 mb-2">
          {{ searchQuery ? 'No posts found' : 'No posts yet' }}
        </h2>
        <p class="text-secondary-600">
          {{ searchQuery ? 'Try adjusting your search terms.' : 'No posts have been published in this category yet.' }}
        </p>
      </div>

      <div v-else>
        <!-- Posts Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 mb-12">
          <PostCard
            v-for="post in paginatedPosts"
            :key="post.id"
            :post="post"
          />
        </div>

        <!-- Pagination -->
        <div v-if="totalPages > 1" class="flex items-center justify-center space-x-4">
          <button
            @click="currentPage > 1 && (currentPage--)"
            :disabled="currentPage === 1"
            class="btn-outline btn-sm"
            :class="{ 'opacity-50 cursor-not-allowed': currentPage === 1 }"
          >
            <ChevronLeftIcon class="h-4 w-4 mr-1" />
            Previous
          </button>

          <div class="flex items-center space-x-2">
            <button
              v-for="page in visiblePages"
              :key="page"
              @click="currentPage = page"
              class="px-3 py-1 text-sm rounded-md"
              :class="{
                'bg-primary-600 text-white': page === currentPage,
                'text-secondary-600 hover:bg-secondary-100': page !== currentPage && page !== '...',
                'text-secondary-400 cursor-default': page === '...'
              }"
              :disabled="page === '...'"
            >
              {{ page }}
            </button>
          </div>

          <button
            @click="currentPage < totalPages && (currentPage++)"
            :disabled="currentPage === totalPages"
            class="btn-outline btn-sm"
            :class="{ 'opacity-50 cursor-not-allowed': currentPage === totalPages }"
          >
            Next
            <ChevronRightIcon class="h-4 w-4 ml-1" />
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import {
  ChevronRightIcon,
  FolderIcon,
  MagnifyingGlassIcon,
  DocumentTextIcon,
  ChevronLeftIcon
} from '@heroicons/vue/24/outline'
import { usePostsStore } from '@/stores/posts'
import { useCategoriesStore } from '@/stores/categories'
import PostCard from '@/components/PostCard.vue'

const route = useRoute()
const postsStore = usePostsStore()
const categoriesStore = useCategoriesStore()

const searchQuery = ref('')
const currentPage = ref(1)
const itemsPerPage = ref(9)

const category = computed(() => {
  return categoriesStore.categories.find(cat => cat.slug === route.params.slug)
})

const categoryPosts = computed(() => {
  if (!category.value) return []
  return postsStore.posts.filter(post => 
    post.status === 'published' && post.category_id === category.value.id
  )
})

const filteredPosts = computed(() => {
  let posts = categoryPosts.value
  
  if (searchQuery.value) {
    const search = searchQuery.value.toLowerCase()
    posts = posts.filter(post => 
      post.title.toLowerCase().includes(search) ||
      post.excerpt?.toLowerCase().includes(search) ||
      post.content.toLowerCase().includes(search)
    )
  }
  
  return posts.sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
})

const totalPages = computed(() => {
  return Math.ceil(filteredPosts.value.length / itemsPerPage.value)
})

const paginatedPosts = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage.value
  const end = start + itemsPerPage.value
  return filteredPosts.value.slice(start, end)
})

const visiblePages = computed(() => {
  const delta = 2
  const range = []
  const rangeWithDots = []
  
  for (let i = Math.max(2, currentPage.value - delta); 
       i <= Math.min(totalPages.value - 1, currentPage.value + delta); 
       i++) {
    range.push(i)
  }
  
  if (currentPage.value - delta > 2) {
    rangeWithDots.push(1, '...')
  } else {
    rangeWithDots.push(1)
  }
  
  rangeWithDots.push(...range)
  
  if (currentPage.value + delta < totalPages.value - 1) {
    rangeWithDots.push('...', totalPages.value)
  } else if (totalPages.value > 1) {
    rangeWithDots.push(totalPages.value)
  }
  
  return rangeWithDots.filter((item, index, arr) => arr.indexOf(item) === index)
})

// Debounced search
let searchTimeout
const debouncedSearch = () => {
  clearTimeout(searchTimeout)
  searchTimeout = setTimeout(() => {
    currentPage.value = 1
  }, 300)
}

// Reset page when route changes
watch(() => route.params.slug, () => {
  currentPage.value = 1
  searchQuery.value = ''
})

onMounted(async () => {
  await Promise.all([
    postsStore.fetchPosts(),
    categoriesStore.fetchCategories()
  ])
  
  // Update page title
  if (category.value) {
    document.title = `${category.value.name} - BlogCMS`
  }
})
</script>
