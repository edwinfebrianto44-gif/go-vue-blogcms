<template>
  <div class="min-h-screen bg-secondary-50">
    <!-- Header -->
    <DashboardHeader />
    
    <!-- Main Content -->
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Page Header -->
      <div class="flex items-center justify-between mb-8">
        <div>
          <h1 class="text-2xl font-bold text-secondary-900">Posts</h1>
          <p class="text-secondary-600">Manage your blog posts</p>
        </div>
        <RouterLink
          to="/dashboard/posts/create"
          class="btn-primary"
        >
          <PlusIcon class="h-5 w-5 mr-2" />
          New Post
        </RouterLink>
      </div>

      <!-- Filters and Search -->
      <div class="bg-white rounded-lg shadow-sm p-6 mb-6">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
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

          <!-- Status Filter -->
          <div>
            <select v-model="filters.status" @change="loadPosts" class="input">
              <option value="">All Status</option>
              <option value="published">Published</option>
              <option value="draft">Draft</option>
            </select>
          </div>

          <!-- Category Filter -->
          <div>
            <select v-model="filters.category" @change="loadPosts" class="input">
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
        </div>
      </div>

      <!-- Posts List -->
      <div class="bg-white rounded-lg shadow-sm overflow-hidden">
        <!-- Loading State -->
        <div v-if="postsStore.isLoading" class="p-8 text-center">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600 mx-auto"></div>
          <p class="text-secondary-600 mt-2">Loading posts...</p>
        </div>

        <!-- Empty State -->
        <div v-else-if="filteredPosts.length === 0" class="p-8 text-center">
          <DocumentTextIcon class="mx-auto h-12 w-12 text-secondary-400 mb-4" />
          <h3 class="text-lg font-medium text-secondary-900 mb-2">No posts found</h3>
          <p class="text-secondary-600 mb-4">
            {{ filters.search || filters.status || filters.category ? 'Try adjusting your filters' : 'Get started by creating your first post' }}
          </p>
          <RouterLink
            v-if="!filters.search && !filters.status && !filters.category"
            to="/dashboard/posts/create"
            class="btn-primary"
          >
            Create your first post
          </RouterLink>
        </div>

        <!-- Posts Table -->
        <div v-else class="overflow-x-auto">
          <table class="min-w-full divide-y divide-secondary-200">
            <thead class="bg-secondary-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-secondary-500 uppercase tracking-wider">
                  Title
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-secondary-500 uppercase tracking-wider">
                  Status
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-secondary-500 uppercase tracking-wider">
                  Category
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-secondary-500 uppercase tracking-wider">
                  Date
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-secondary-500 uppercase tracking-wider">
                  Views
                </th>
                <th class="relative px-6 py-3">
                  <span class="sr-only">Actions</span>
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-secondary-200">
              <tr
                v-for="post in paginatedPosts"
                :key="post.id"
                class="hover:bg-secondary-50"
              >
                <td class="px-6 py-4 whitespace-nowrap">
                  <div class="flex items-center">
                    <div class="flex-shrink-0 h-10 w-10">
                      <img
                        v-if="post.featured_image"
                        :src="post.featured_image"
                        :alt="post.title"
                        class="h-10 w-10 rounded-lg object-cover"
                      />
                      <div
                        v-else
                        class="h-10 w-10 rounded-lg bg-secondary-200 flex items-center justify-center"
                      >
                        <DocumentTextIcon class="h-5 w-5 text-secondary-500" />
                      </div>
                    </div>
                    <div class="ml-4">
                      <div class="text-sm font-medium text-secondary-900 max-w-xs truncate">
                        {{ post.title }}
                      </div>
                      <div class="text-sm text-secondary-500">
                        {{ post.excerpt ? post.excerpt.substring(0, 60) + '...' : 'No excerpt' }}
                      </div>
                    </div>
                  </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                  <span
                    class="inline-flex px-2 py-1 text-xs font-semibold rounded-full"
                    :class="{
                      'bg-green-100 text-green-800': post.status === 'published',
                      'bg-yellow-100 text-yellow-800': post.status === 'draft'
                    }"
                  >
                    {{ post.status }}
                  </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-secondary-900">
                  {{ getCategoryName(post.category_id) }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-secondary-500">
                  {{ formatDate(post.created_at) }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-secondary-500">
                  {{ post.views || 0 }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <div class="flex items-center justify-end space-x-2">
                    <RouterLink
                      :to="`/posts/${post.slug}`"
                      class="text-secondary-600 hover:text-secondary-900"
                      title="View post"
                    >
                      <EyeIcon class="h-4 w-4" />
                    </RouterLink>
                    <RouterLink
                      :to="`/dashboard/posts/${post.id}/edit`"
                      class="text-primary-600 hover:text-primary-900"
                      title="Edit post"
                    >
                      <PencilIcon class="h-4 w-4" />
                    </RouterLink>
                    <button
                      @click="deletePost(post)"
                      class="text-red-600 hover:text-red-900"
                      title="Delete post"
                    >
                      <TrashIcon class="h-4 w-4" />
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Pagination -->
        <div
          v-if="filteredPosts.length > itemsPerPage"
          class="bg-white px-6 py-3 border-t border-secondary-200 flex items-center justify-between"
        >
          <div class="flex-1 flex justify-between sm:hidden">
            <button
              @click="currentPage > 1 && (currentPage--)"
              :disabled="currentPage === 1"
              class="btn-outline btn-sm"
              :class="{ 'opacity-50 cursor-not-allowed': currentPage === 1 }"
            >
              Previous
            </button>
            <button
              @click="currentPage < totalPages && (currentPage++)"
              :disabled="currentPage === totalPages"
              class="btn-outline btn-sm"
              :class="{ 'opacity-50 cursor-not-allowed': currentPage === totalPages }"
            >
              Next
            </button>
          </div>
          <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
            <div>
              <p class="text-sm text-secondary-700">
                Showing
                <span class="font-medium">{{ (currentPage - 1) * itemsPerPage + 1 }}</span>
                to
                <span class="font-medium">{{ Math.min(currentPage * itemsPerPage, filteredPosts.length) }}</span>
                of
                <span class="font-medium">{{ filteredPosts.length }}</span>
                results
              </p>
            </div>
            <div>
              <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
                <button
                  @click="currentPage > 1 && (currentPage--)"
                  :disabled="currentPage === 1"
                  class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-secondary-300 bg-white text-sm font-medium text-secondary-500 hover:bg-secondary-50"
                  :class="{ 'opacity-50 cursor-not-allowed': currentPage === 1 }"
                >
                  <ChevronLeftIcon class="h-5 w-5" />
                </button>
                
                <button
                  v-for="page in visiblePages"
                  :key="page"
                  @click="currentPage = page"
                  class="relative inline-flex items-center px-4 py-2 border text-sm font-medium"
                  :class="{
                    'z-10 bg-primary-50 border-primary-500 text-primary-600': page === currentPage,
                    'bg-white border-secondary-300 text-secondary-500 hover:bg-secondary-50': page !== currentPage
                  }"
                >
                  {{ page }}
                </button>
                
                <button
                  @click="currentPage < totalPages && (currentPage++)"
                  :disabled="currentPage === totalPages"
                  class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-secondary-300 bg-white text-sm font-medium text-secondary-500 hover:bg-secondary-50"
                  :class="{ 'opacity-50 cursor-not-allowed': currentPage === totalPages }"
                >
                  <ChevronRightIcon class="h-5 w-5" />
                </button>
              </nav>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { RouterLink } from 'vue-router'
import {
  PlusIcon,
  MagnifyingGlassIcon,
  DocumentTextIcon,
  EyeIcon,
  PencilIcon,
  TrashIcon,
  ChevronLeftIcon,
  ChevronRightIcon
} from '@heroicons/vue/24/outline'
import { usePostsStore } from '@/stores/posts'
import { useCategoriesStore } from '@/stores/categories'
import DashboardHeader from '@/components/dashboard/DashboardHeader.vue'

const postsStore = usePostsStore()
const categoriesStore = useCategoriesStore()

const filters = ref({
  search: '',
  status: '',
  category: ''
})

const currentPage = ref(1)
const itemsPerPage = ref(10)

const filteredPosts = computed(() => {
  let posts = [...postsStore.posts]
  
  if (filters.value.search) {
    const search = filters.value.search.toLowerCase()
    posts = posts.filter(post => 
      post.title.toLowerCase().includes(search) ||
      post.content.toLowerCase().includes(search)
    )
  }
  
  if (filters.value.status) {
    posts = posts.filter(post => post.status === filters.value.status)
  }
  
  if (filters.value.category) {
    posts = posts.filter(post => post.category_id === parseInt(filters.value.category))
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

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

const getCategoryName = (categoryId) => {
  const category = categoriesStore.categories.find(c => c.id === categoryId)
  return category ? category.name : 'Uncategorized'
}

const deletePost = async (post) => {
  if (!confirm(`Are you sure you want to delete "${post.title}"?`)) {
    return
  }
  
  const result = await postsStore.deletePost(post.id)
  if (result.success) {
    if (window.toast) {
      window.toast.success('Post deleted successfully')
    }
  } else {
    if (window.toast) {
      window.toast.error('Error', result.message)
    }
  }
}

// Debounced search
let searchTimeout
const debouncedSearch = () => {
  clearTimeout(searchTimeout)
  searchTimeout = setTimeout(() => {
    currentPage.value = 1
    loadPosts()
  }, 300)
}

const loadPosts = async () => {
  await postsStore.fetchPosts()
}

// Reset page when filters change
watch([() => filters.value.status, () => filters.value.category], () => {
  currentPage.value = 1
})

onMounted(async () => {
  await Promise.all([
    postsStore.fetchPosts(),
    categoriesStore.fetchCategories()
  ])
})
</script>
