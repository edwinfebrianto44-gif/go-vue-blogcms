<template>
  <div class="min-h-screen bg-secondary-50">
    <!-- Header -->
    <DashboardHeader />
    
    <!-- Main Content -->
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Welcome Section -->
      <div class="mb-8">
        <div class="bg-white rounded-lg shadow-sm p-6">
          <h1 class="text-2xl font-bold text-secondary-900 mb-2">
            Welcome back, {{ authStore.user?.name }}!
          </h1>
          <p class="text-secondary-600">
            Here's what's happening with your blog today.
          </p>
        </div>
      </div>

      <!-- Stats Cards -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div class="bg-white rounded-lg shadow-sm p-6">
          <div class="flex items-center">
            <div class="p-2 bg-blue-100 rounded-lg">
              <DocumentTextIcon class="h-6 w-6 text-blue-600" />
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-secondary-600">Total Posts</p>
              <p class="text-2xl font-bold text-secondary-900">{{ stats.posts || 0 }}</p>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow-sm p-6">
          <div class="flex items-center">
            <div class="p-2 bg-green-100 rounded-lg">
              <EyeIcon class="h-6 w-6 text-green-600" />
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-secondary-600">Total Views</p>
              <p class="text-2xl font-bold text-secondary-900">{{ stats.views || 0 }}</p>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow-sm p-6">
          <div class="flex items-center">
            <div class="p-2 bg-purple-100 rounded-lg">
              <ChatBubbleLeftEllipsisIcon class="h-6 w-6 text-purple-600" />
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-secondary-600">Comments</p>
              <p class="text-2xl font-bold text-secondary-900">{{ stats.comments || 0 }}</p>
            </div>
          </div>
        </div>

        <div class="bg-white rounded-lg shadow-sm p-6">
          <div class="flex items-center">
            <div class="p-2 bg-orange-100 rounded-lg">
              <FolderIcon class="h-6 w-6 text-orange-600" />
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-secondary-600">Categories</p>
              <p class="text-2xl font-bold text-secondary-900">{{ stats.categories || 0 }}</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Quick Actions -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
        <!-- Quick Actions Card -->
        <div class="bg-white rounded-lg shadow-sm p-6">
          <h2 class="text-lg font-semibold text-secondary-900 mb-4">Quick Actions</h2>
          <div class="space-y-3">
            <RouterLink
              to="/dashboard/posts/create"
              class="flex items-center p-3 border border-secondary-200 rounded-lg hover:bg-secondary-50 transition-colors"
            >
              <PlusCircleIcon class="h-5 w-5 text-primary-600 mr-3" />
              <span class="font-medium text-secondary-900">Create New Post</span>
            </RouterLink>
            
            <RouterLink
              to="/dashboard/categories"
              class="flex items-center p-3 border border-secondary-200 rounded-lg hover:bg-secondary-50 transition-colors"
            >
              <TagIcon class="h-5 w-5 text-green-600 mr-3" />
              <span class="font-medium text-secondary-900">Manage Categories</span>
            </RouterLink>
            
            <RouterLink
              to="/dashboard/settings"
              class="flex items-center p-3 border border-secondary-200 rounded-lg hover:bg-secondary-50 transition-colors"
            >
              <CogIcon class="h-5 w-5 text-purple-600 mr-3" />
              <span class="font-medium text-secondary-900">Settings</span>
            </RouterLink>
          </div>
        </div>

        <!-- Recent Activity -->
        <div class="bg-white rounded-lg shadow-sm p-6">
          <h2 class="text-lg font-semibold text-secondary-900 mb-4">Recent Activity</h2>
          <div v-if="recentPosts.length > 0" class="space-y-3">
            <div
              v-for="post in recentPosts.slice(0, 5)"
              :key="post.id"
              class="flex items-center justify-between p-3 border border-secondary-100 rounded-lg"
            >
              <div class="flex-1">
                <h3 class="font-medium text-secondary-900 text-sm truncate">{{ post.title }}</h3>
                <p class="text-xs text-secondary-500 mt-1">
                  {{ formatDate(post.created_at) }}
                </p>
              </div>
              <div class="flex items-center space-x-2">
                <span
                  class="px-2 py-1 text-xs rounded-full"
                  :class="{
                    'bg-green-100 text-green-800': post.status === 'published',
                    'bg-yellow-100 text-yellow-800': post.status === 'draft'
                  }"
                >
                  {{ post.status }}
                </span>
                <RouterLink
                  :to="`/dashboard/posts/${post.id}/edit`"
                  class="text-primary-600 hover:text-primary-700"
                >
                  <PencilIcon class="h-4 w-4" />
                </RouterLink>
              </div>
            </div>
          </div>
          <div v-else class="text-center py-8">
            <DocumentTextIcon class="mx-auto h-12 w-12 text-secondary-400 mb-4" />
            <p class="text-secondary-500">No posts yet</p>
            <RouterLink
              to="/dashboard/posts/create"
              class="text-primary-600 hover:text-primary-700 font-medium text-sm"
            >
              Create your first post
            </RouterLink>
          </div>
        </div>
      </div>

      <!-- Recent Comments (if admin) -->
      <div v-if="authStore.user?.role === 'admin'" class="bg-white rounded-lg shadow-sm p-6">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-lg font-semibold text-secondary-900">Recent Comments</h2>
          <RouterLink
            to="/dashboard/comments"
            class="text-primary-600 hover:text-primary-700 text-sm font-medium"
          >
            View all
          </RouterLink>
        </div>
        
        <div v-if="recentComments.length > 0" class="space-y-4">
          <div
            v-for="comment in recentComments.slice(0, 5)"
            :key="comment.id"
            class="border border-secondary-100 rounded-lg p-4"
          >
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <div class="flex items-center space-x-2 mb-2">
                  <span class="font-medium text-secondary-900 text-sm">{{ comment.author_name }}</span>
                  <span class="text-secondary-400">•</span>
                  <span class="text-xs text-secondary-500">{{ formatDate(comment.created_at) }}</span>
                </div>
                <p class="text-sm text-secondary-700 mb-2">{{ comment.content }}</p>
                <p class="text-xs text-secondary-500">
                  on <RouterLink :to="`/posts/${comment.post_slug}`" class="text-primary-600 hover:text-primary-700">{{ comment.post_title }}</RouterLink>
                </p>
              </div>
              <div class="flex items-center space-x-2">
                <button
                  @click="approveComment(comment.id)"
                  v-if="!comment.approved"
                  class="text-green-600 hover:text-green-700"
                >
                  <CheckCircleIcon class="h-4 w-4" />
                </button>
                <button
                  @click="deleteComment(comment.id)"
                  class="text-red-600 hover:text-red-700"
                >
                  <TrashIcon class="h-4 w-4" />
                </button>
              </div>
            </div>
          </div>
        </div>
        <div v-else class="text-center py-8">
          <ChatBubbleLeftEllipsisIcon class="mx-auto h-12 w-12 text-secondary-400 mb-4" />
          <p class="text-secondary-500">No recent comments</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { RouterLink } from 'vue-router'
import {
  DocumentTextIcon,
  EyeIcon,
  ChatBubbleLeftEllipsisIcon,
  FolderIcon,
  PlusCircleIcon,
  TagIcon,
  CogIcon,
  PencilIcon,
  CheckCircleIcon,
  TrashIcon
} from '@heroicons/vue/24/outline'
import { useAuthStore } from '@/stores/auth'
import { usePostsStore } from '@/stores/posts'
import DashboardHeader from '@/components/dashboard/DashboardHeader.vue'
import api from '@/services/api'

const authStore = useAuthStore()
const postsStore = usePostsStore()

const stats = ref({
  posts: 0,
  views: 0,
  comments: 0,
  categories: 0
})

const recentPosts = ref([])
const recentComments = ref([])

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

const loadDashboardData = async () => {
  try {
    // Load stats
    const [
      postsResponse,
      categoriesResponse,
      commentsResponse
    ] = await Promise.all([
      api.get('/posts'),
      api.get('/categories'),
      authStore.user?.role === 'admin' ? api.get('/comments') : Promise.resolve({ data: { data: [] } })
    ])

    stats.value = {
      posts: postsResponse.data.data.length,
      views: postsResponse.data.data.reduce((total, post) => total + (post.views || 0), 0),
      comments: commentsResponse.data.data.length,
      categories: categoriesResponse.data.data.length
    }

    // Recent posts
    recentPosts.value = postsResponse.data.data
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
      .slice(0, 10)

    // Recent comments (admin only)
    if (authStore.user?.role === 'admin') {
      recentComments.value = commentsResponse.data.data
        .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
        .slice(0, 10)
    }
  } catch (error) {
    console.error('Error loading dashboard data:', error)
    if (window.toast) {
      window.toast.error('Error', 'Failed to load dashboard data')
    }
  }
}

const approveComment = async (commentId) => {
  try {
    await api.put(`/comments/${commentId}`, { approved: true })
    const comment = recentComments.value.find(c => c.id === commentId)
    if (comment) {
      comment.approved = true
    }
    if (window.toast) {
      window.toast.success('Comment approved')
    }
  } catch (error) {
    console.error('Error approving comment:', error)
    if (window.toast) {
      window.toast.error('Error', 'Failed to approve comment')
    }
  }
}

const deleteComment = async (commentId) => {
  if (!confirm('Are you sure you want to delete this comment?')) {
    return
  }
  
  try {
    await api.delete(`/comments/${commentId}`)
    recentComments.value = recentComments.value.filter(c => c.id !== commentId)
    stats.value.comments--
    if (window.toast) {
      window.toast.success('Comment deleted')
    }
  } catch (error) {
    console.error('Error deleting comment:', error)
    if (window.toast) {
      window.toast.error('Error', 'Failed to delete comment')
    }
  }
}

onMounted(() => {
  loadDashboardData()
})
</script>
