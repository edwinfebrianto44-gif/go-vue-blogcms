<template>
  <div class="bg-white rounded-lg shadow-sm p-6">
    <div class="flex items-center justify-between mb-6">
      <h2 class="text-xl font-bold text-secondary-900">
        Comments ({{ comments.length }})
      </h2>
      <button
        v-if="authStore.isAuthenticated"
        @click="showCommentForm = !showCommentForm"
        class="btn-primary btn-sm"
      >
        <ChatBubbleLeftEllipsisIcon class="h-4 w-4 mr-2" />
        Add Comment
      </button>
    </div>

    <!-- Comment Form -->
    <div v-if="showCommentForm && authStore.isAuthenticated" class="mb-8">
      <form @submit.prevent="submitComment" class="space-y-4">
        <div>
          <label for="comment" class="label">Your Comment</label>
          <textarea
            id="comment"
            v-model="newComment.content"
            rows="4"
            required
            class="input"
            :class="{ 'border-red-300 focus:border-red-500 focus:ring-red-500': errors.content }"
            placeholder="Share your thoughts..."
          ></textarea>
          <p v-if="errors.content" class="text-red-600 text-sm mt-1">{{ errors.content }}</p>
        </div>

        <div class="flex items-center justify-between">
          <p class="text-sm text-secondary-600">
            Commenting as <strong>{{ authStore.user?.name }}</strong>
          </p>
          <div class="flex items-center space-x-3">
            <button
              type="button"
              @click="showCommentForm = false"
              class="btn-outline btn-sm"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="isSubmitting"
              class="btn-primary btn-sm"
            >
              <span v-if="!isSubmitting">Post Comment</span>
              <span v-else class="flex items-center">
                <svg class="animate-spin -ml-1 mr-2 h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Posting...
              </span>
            </button>
          </div>
        </div>
      </form>
    </div>

    <!-- Guest Comment Prompt -->
    <div v-if="showCommentForm && !authStore.isAuthenticated" class="mb-8 p-4 bg-secondary-50 rounded-lg">
      <p class="text-secondary-700 mb-4">Please sign in to leave a comment.</p>
      <div class="flex items-center space-x-3">
        <RouterLink to="/login" class="btn-primary btn-sm">
          Sign In
        </RouterLink>
        <RouterLink to="/register" class="btn-outline btn-sm">
          Create Account
        </RouterLink>
      </div>
    </div>

    <!-- Comments List -->
    <div v-if="isLoading" class="text-center py-8">
      <div class="animate-spin rounded-full h-6 w-6 border-b-2 border-primary-600 mx-auto"></div>
      <p class="text-secondary-600 mt-2">Loading comments...</p>
    </div>

    <div v-else-if="comments.length === 0" class="text-center py-8">
      <ChatBubbleLeftEllipsisIcon class="mx-auto h-12 w-12 text-secondary-400 mb-4" />
      <h3 class="text-lg font-medium text-secondary-900 mb-2">No comments yet</h3>
      <p class="text-secondary-600">Be the first to share your thoughts!</p>
    </div>

    <div v-else class="space-y-6">
      <div
        v-for="comment in sortedComments"
        :key="comment.id"
        class="border border-secondary-200 rounded-lg p-4"
      >
        <div class="flex items-start justify-between">
          <div class="flex items-start space-x-3 flex-1">
            <!-- Avatar -->
            <div class="h-8 w-8 bg-primary-100 rounded-full flex items-center justify-center flex-shrink-0">
              <span class="text-primary-700 font-medium text-sm">
                {{ comment.author_name?.charAt(0)?.toUpperCase() }}
              </span>
            </div>

            <!-- Comment Content -->
            <div class="flex-1 min-w-0">
              <div class="flex items-center space-x-2 mb-2">
                <h4 class="font-medium text-secondary-900">{{ comment.author_name }}</h4>
                <span class="text-secondary-400">•</span>
                <time class="text-sm text-secondary-500" :datetime="comment.created_at">
                  {{ formatDate(comment.created_at) }}
                </time>
                <span
                  v-if="!comment.approved"
                  class="inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-yellow-100 text-yellow-800"
                >
                  Pending Review
                </span>
              </div>
              <p class="text-secondary-700 whitespace-pre-wrap">{{ comment.content }}</p>
            </div>
          </div>

          <!-- Actions -->
          <div v-if="canModerateComment(comment)" class="flex items-center space-x-2 ml-4">
            <button
              v-if="!comment.approved"
              @click="approveComment(comment.id)"
              class="text-green-600 hover:text-green-700 p-1"
              title="Approve comment"
            >
              <CheckCircleIcon class="h-4 w-4" />
            </button>
            <button
              @click="deleteComment(comment.id)"
              class="text-red-600 hover:text-red-700 p-1"
              title="Delete comment"
            >
              <TrashIcon class="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Load More Button -->
    <div v-if="hasMoreComments" class="text-center mt-6">
      <button
        @click="loadMoreComments"
        :disabled="isLoadingMore"
        class="btn-outline"
      >
        <span v-if="!isLoadingMore">Load More Comments</span>
        <span v-else class="flex items-center">
          <svg class="animate-spin -ml-1 mr-2 h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          Loading...
        </span>
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, reactive } from 'vue'
import { RouterLink } from 'vue-router'
import {
  ChatBubbleLeftEllipsisIcon,
  CheckCircleIcon,
  TrashIcon
} from '@heroicons/vue/24/outline'
import { useAuthStore } from '@/stores/auth'
import api from '@/services/api'

const props = defineProps({
  postId: {
    type: Number,
    required: true
  }
})

const authStore = useAuthStore()

const comments = ref([])
const showCommentForm = ref(false)
const isLoading = ref(true)
const isSubmitting = ref(false)
const isLoadingMore = ref(false)
const hasMoreComments = ref(false)
const currentPage = ref(1)
const errors = ref({})

const newComment = reactive({
  content: ''
})

const sortedComments = computed(() => {
  return [...comments.value].sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
})

const canModerateComment = (comment) => {
  return authStore.user?.role === 'admin' || authStore.user?.id === comment.author_id
}

const formatDate = (dateString) => {
  const date = new Date(dateString)
  const now = new Date()
  const diffInMinutes = Math.floor((now - date) / (1000 * 60))
  
  if (diffInMinutes < 1) return 'Just now'
  if (diffInMinutes < 60) return `${diffInMinutes} minutes ago`
  
  const diffInHours = Math.floor(diffInMinutes / 60)
  if (diffInHours < 24) return `${diffInHours} hours ago`
  
  const diffInDays = Math.floor(diffInHours / 24)
  if (diffInDays < 7) return `${diffInDays} days ago`
  
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })
}

const loadComments = async (page = 1) => {
  try {
    const response = await api.get(`/comments/post/${props.postId}?page=${page}&limit=10`)
    
    if (page === 1) {
      comments.value = response.data.data
    } else {
      comments.value.push(...response.data.data)
    }
    
    hasMoreComments.value = response.data.pagination.has_more
    currentPage.value = page
  } catch (error) {
    console.error('Error loading comments:', error)
    if (window.toast) {
      window.toast.error('Error', 'Failed to load comments')
    }
  } finally {
    isLoading.value = false
    isLoadingMore.value = false
  }
}

const submitComment = async () => {
  errors.value = {}
  
  if (!newComment.content.trim()) {
    errors.value.content = 'Comment content is required'
    return
  }
  
  if (newComment.content.length > 1000) {
    errors.value.content = 'Comment must be less than 1000 characters'
    return
  }
  
  isSubmitting.value = true
  
  try {
    const response = await api.post('/comments', {
      post_id: props.postId,
      content: newComment.content.trim()
    })
    
    // Add new comment to the beginning of the list
    comments.value.unshift(response.data.data)
    
    // Reset form
    newComment.content = ''
    showCommentForm.value = false
    
    if (window.toast) {
      window.toast.success('Comment added successfully!')
    }
  } catch (error) {
    console.error('Error submitting comment:', error)
    const message = error.response?.data?.message || 'Failed to submit comment'
    if (window.toast) {
      window.toast.error('Error', message)
    }
  } finally {
    isSubmitting.value = false
  }
}

const approveComment = async (commentId) => {
  try {
    await api.put(`/comments/${commentId}`, { approved: true })
    
    const comment = comments.value.find(c => c.id === commentId)
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
    
    comments.value = comments.value.filter(c => c.id !== commentId)
    
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

const loadMoreComments = async () => {
  isLoadingMore.value = true
  await loadComments(currentPage.value + 1)
}

onMounted(() => {
  loadComments()
})
</script>
