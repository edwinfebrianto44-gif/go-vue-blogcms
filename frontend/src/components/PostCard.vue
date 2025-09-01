<template>
  <article class="card overflow-hidden hover:shadow-md transition-shadow">
    <!-- Featured Image -->
    <div class="aspect-w-16 aspect-h-9 bg-secondary-200">
      <img
        v-if="post.featured_image"
        :src="post.featured_image"
        :alt="post.title"
        class="object-cover w-full h-48"
      />
      <div v-else class="flex items-center justify-center h-48 bg-secondary-100">
        <svg class="h-12 w-12 text-secondary-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path>
        </svg>
      </div>
    </div>

    <!-- Content -->
    <div class="p-6">
      <!-- Category Badge -->
      <div class="mb-3">
        <RouterLink
          v-if="post.category"
          :to="`/categories/${post.category.slug}`"
          class="badge-primary hover:bg-primary-200 transition-colors"
        >
          {{ post.category.name }}
        </RouterLink>
      </div>

      <!-- Title -->
      <h2 class="text-xl font-bold text-secondary-900 mb-3 line-clamp-2">
        <RouterLink
          :to="`/posts/${post.slug}`"
          class="hover:text-primary-600 transition-colors"
        >
          {{ post.title }}
        </RouterLink>
      </h2>

      <!-- Summary -->
      <p class="text-secondary-600 mb-4 line-clamp-3">
        {{ post.summary || post.excerpt }}
      </p>

      <!-- Meta -->
      <div class="flex items-center justify-between text-sm text-secondary-500">
        <div class="flex items-center space-x-2">
          <div class="h-6 w-6 bg-primary-100 rounded-full flex items-center justify-center">
            <span class="text-primary-600 font-medium text-xs">
              {{ post.author?.name?.charAt(0).toUpperCase() }}
            </span>
          </div>
          <span>{{ post.author?.name }}</span>
        </div>
        
        <time :datetime="post.created_at">
          {{ formatDate(post.created_at) }}
        </time>
      </div>

      <!-- Status Badge (for dashboard) -->
      <div v-if="showStatus" class="mt-3">
        <span
          :class="[
            'badge',
            post.status === 'published' ? 'badge-success' :
            post.status === 'draft' ? 'badge-secondary' :
            'badge-warning'
          ]"
        >
          {{ post.status }}
        </span>
      </div>
    </div>
  </article>
</template>

<script setup>
import { RouterLink } from 'vue-router'
import { format, parseISO } from 'date-fns'

defineProps({
  post: {
    type: Object,
    required: true
  },
  showStatus: {
    type: Boolean,
    default: false
  }
})

const formatDate = (dateString) => {
  try {
    return format(parseISO(dateString), 'MMM d, yyyy')
  } catch (error) {
    return 'Invalid date'
  }
}
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.line-clamp-3 {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
