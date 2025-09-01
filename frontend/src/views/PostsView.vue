<template>
  <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
    <!-- Page Header -->
    <div class="mb-8">
      <div class="flex items-center space-x-4 text-sm text-secondary-600 mb-4">
        <RouterLink to="/" class="hover:text-primary-600">Home</RouterLink>
        <ChevronRightIcon class="h-4 w-4" />
        <span class="text-secondary-900">All Posts</span>
      </div>
      <h1 class="text-3xl font-bold text-secondary-900">All Posts</h1>
      <p class="text-secondary-600 mt-2">Discover our latest articles and insights</p>
    </div>

    <!-- Filters -->
    <div class="bg-white rounded-lg shadow-sm p-6 mb-8">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <!-- Search -->
        <div class="md:col-span-2">
          <div class="relative">
            <MagnifyingGlassIcon class="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-secondary-400" />
            <input
              v-model="filters.search"
              type="text"
              placeholder="Search posts..."
              class="input pl-10"
              @input="debouncedSearch"
            />
          </div>
        </div>

        <!-- Category Filter -->
        <div>
          <select v-model="filters.category" @change="loadPosts" class="input">
            <option value="">All Categories</option>
            <option
              v-for="category in categoriesStore.categories"
              :key="category.id"
              :value="category.slug"
            >
              {{ category.name }}
            </option>
          </select>
        </div>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="postsStore.isLoading" class="text-center py-12">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600 mx-auto"></div>
      <p class="text-secondary-600 mt-4">Loading posts...</p>
    </div>

    <!-- Empty State -->
    <div v-else-if="filteredPosts.length === 0" class="text-center py-12">
      <DocumentTextIcon class="mx-auto h-16 w-16 text-secondary-400 mb-4" />
      <h2 class="text-2xl font-bold text-secondary-900 mb-2">No posts found</h2>
      <p class="text-secondary-600 mb-6">
        {{ filters.search || filters.category ? 'Try adjusting your filters to find what you\'re looking for.' : 'No posts have been published yet.' }}
      </p>
      <RouterLink to="/" class="btn-primary">
        Back to Home
      </RouterLink>
    </div>

    <!-- Posts Grid -->
    <div v-else>
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
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import {
  ChevronRightIcon,
  MagnifyingGlassIcon,
  DocumentTextIcon,
  ChevronLeftIcon,
  ChevronRightIcon
} from '@heroicons/vue/24/outline'
import { usePostsStore } from '@/stores/posts'
import { useCategoriesStore } from '@/stores/categories'
import PostCard from '@/components/ui/PostCard.vue'

const route = useRoute()
const postsStore = usePostsStore()
const categoriesStore = useCategoriesStore()

const filters = ref({
  search: '',
  category: ''
})

const currentPage = ref(1)
const itemsPerPage = ref(9)

const filteredPosts = computed(() => {
  let posts = postsStore.posts.filter(post => post.status === 'published')
  
  if (filters.value.search) {
    const search = filters.value.search.toLowerCase()
    posts = posts.filter(post => 
      post.title.toLowerCase().includes(search) ||
      post.excerpt?.toLowerCase().includes(search) ||
      post.content.toLowerCase().includes(search)
    )
  }
  
  if (filters.value.category) {
    posts = posts.filter(post => post.category?.slug === filters.value.category)
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

const loadPosts = async () => {
  await postsStore.fetchPosts()
}

// Reset page when filters change
watch([() => filters.value.category], () => {
  currentPage.value = 1
})

// Initialize from query params
onMounted(async () => {
  if (route.query.category) {
    filters.value.category = route.query.category
  }
  if (route.query.search) {
    filters.value.search = route.query.search
  }
  
  await Promise.all([
    postsStore.fetchPosts(),
    categoriesStore.fetchCategories()
  ])
})
</script>
