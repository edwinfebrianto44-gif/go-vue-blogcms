<template>
  <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
    <!-- Header -->
    <div class="mb-8">
      <div class="flex items-center space-x-4 text-sm text-secondary-600 mb-4">
        <RouterLink to="/" class="hover:text-primary-600">Home</RouterLink>
        <ChevronRightIcon class="h-4 w-4" />
        <RouterLink 
          :to="`/category/${post?.category?.slug}`" 
          class="hover:text-primary-600"
          v-if="post?.category"
        >
          {{ post.category.name }}
        </RouterLink>
        <ChevronRightIcon class="h-4 w-4" v-if="post?.category" />
        <span class="text-secondary-900">{{ post?.title }}</span>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="postsStore.isLoading" class="text-center py-12">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600 mx-auto"></div>
      <p class="text-secondary-600 mt-4">Loading post...</p>
    </div>

    <!-- Post Not Found -->
    <div v-else-if="!post" class="text-center py-12">
      <DocumentTextIcon class="mx-auto h-16 w-16 text-secondary-400 mb-4" />
      <h1 class="text-2xl font-bold text-secondary-900 mb-2">Post not found</h1>
      <p class="text-secondary-600 mb-6">The post you're looking for doesn't exist or has been removed.</p>
      <RouterLink to="/" class="btn-primary">
        Back to Home
      </RouterLink>
    </div>

    <!-- Post Content -->
    <article v-else class="prose prose-lg max-w-none">
      <!-- Featured Image -->
      <div v-if="post.featured_image" class="mb-8">
        <img
          :src="post.featured_image"
          :alt="post.title"
          class="w-full h-64 sm:h-80 lg:h-96 object-cover rounded-lg shadow-lg"
        />
      </div>

      <!-- Post Header -->
      <header class="mb-8">
        <!-- Category Badge -->
        <div v-if="post.category" class="mb-4">
          <RouterLink
            :to="`/category/${post.category.slug}`"
            class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-primary-100 text-primary-800 hover:bg-primary-200 transition-colors"
          >
            {{ post.category.name }}
          </RouterLink>
        </div>

        <!-- Title -->
        <h1 class="text-3xl sm:text-4xl lg:text-5xl font-bold text-secondary-900 leading-tight mb-6">
          {{ post.title }}
        </h1>

        <!-- Excerpt -->
        <div v-if="post.excerpt" class="text-xl text-secondary-600 mb-6 leading-relaxed">
          {{ post.excerpt }}
        </div>

        <!-- Meta Information -->
        <div class="flex flex-wrap items-center gap-6 text-sm text-secondary-600 border-b border-secondary-200 pb-6">
          <!-- Author -->
          <div class="flex items-center">
            <div class="h-8 w-8 bg-primary-100 rounded-full flex items-center justify-center mr-3">
              <span class="text-primary-700 font-medium text-sm">
                {{ post.author?.name?.charAt(0)?.toUpperCase() }}
              </span>
            </div>
            <div>
              <p class="font-medium text-secondary-900">{{ post.author?.name }}</p>
            </div>
          </div>

          <!-- Date -->
          <div class="flex items-center">
            <CalendarIcon class="h-4 w-4 mr-2" />
            <time :datetime="post.created_at">
              {{ formatDate(post.created_at) }}
            </time>
          </div>

          <!-- Reading Time -->
          <div class="flex items-center">
            <ClockIcon class="h-4 w-4 mr-2" />
            <span>{{ readingTime }} min read</span>
          </div>

          <!-- Views -->
          <div class="flex items-center">
            <EyeIcon class="h-4 w-4 mr-2" />
            <span>{{ post.views || 0 }} views</span>
          </div>
        </div>
      </header>

      <!-- Post Content -->
      <div 
        class="prose prose-lg max-w-none prose-headings:text-secondary-900 prose-p:text-secondary-700 prose-strong:text-secondary-900 prose-a:text-primary-600 hover:prose-a:text-primary-700"
        v-html="post.content"
      ></div>

      <!-- Tags -->
      <div v-if="post.tags && post.tags.length > 0" class="mt-8 pt-8 border-t border-secondary-200">
        <h3 class="text-lg font-semibold text-secondary-900 mb-4">Tags</h3>
        <div class="flex flex-wrap gap-2">
          <span
            v-for="tag in post.tags"
            :key="tag"
            class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-secondary-100 text-secondary-800"
          >
            #{{ tag }}
          </span>
        </div>
      </div>

      <!-- Social Share -->
      <div class="mt-8 pt-8 border-t border-secondary-200">
        <h3 class="text-lg font-semibold text-secondary-900 mb-4">Share this post</h3>
        <div class="flex items-center space-x-4">
          <button
            @click="shareOnTwitter"
            class="flex items-center px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
          >
            <svg class="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 24 24">
              <path d="M8.29 20.251c7.547 0 11.675-6.253 11.675-11.675 0-.178 0-.355-.012-.53A8.348 8.348 0 0022 5.92a8.19 8.19 0 01-2.357.646 4.118 4.118 0 001.804-2.27 8.224 8.224 0 01-2.605.996 4.107 4.107 0 00-6.993 3.743 11.65 11.65 0 01-8.457-4.287 4.106 4.106 0 001.27 5.477A4.072 4.072 0 012.8 9.713v.052a4.105 4.105 0 003.292 4.022 4.095 4.095 0 01-1.853.07 4.108 4.108 0 003.834 2.85A8.233 8.233 0 012 18.407a11.616 11.616 0 006.29 1.84"/>
            </svg>
            Twitter
          </button>
          
          <button
            @click="shareOnFacebook"
            class="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <svg class="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 24 24">
              <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
            </svg>
            Facebook
          </button>
          
          <button
            @click="copyLink"
            class="flex items-center px-4 py-2 bg-secondary-600 text-white rounded-lg hover:bg-secondary-700 transition-colors"
          >
            <LinkIcon class="w-4 h-4 mr-2" />
            Copy Link
          </button>
        </div>
      </div>
    </article>

    <!-- Comments Section -->
    <div v-if="post" class="mt-12 pt-8 border-t-2 border-secondary-200">
      <CommentsSection :post-id="post.id" />
    </div>

    <!-- Related Posts -->
    <div v-if="relatedPosts.length > 0" class="mt-12 pt-8 border-t border-secondary-200">
      <h2 class="text-2xl font-bold text-secondary-900 mb-6">Related Posts</h2>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <PostCard
          v-for="relatedPost in relatedPosts"
          :key="relatedPost.id"
          :post="relatedPost"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import {
  ChevronRightIcon,
  DocumentTextIcon,
  CalendarIcon,
  ClockIcon,
  EyeIcon,
  LinkIcon
} from '@heroicons/vue/24/outline'
import { usePostsStore } from '@/stores/posts'
import PostCard from '@/components/ui/PostCard.vue'
import CommentsSection from '@/components/comments/CommentsSection.vue'

const route = useRoute()
const router = useRouter()
const postsStore = usePostsStore()

const post = ref(null)
const relatedPosts = ref([])

const readingTime = computed(() => {
  if (!post.value?.content) return 0
  const wordsPerMinute = 200
  const words = post.value.content.replace(/<[^>]*>/g, '').split(/\s+/).length
  return Math.ceil(words / wordsPerMinute)
})

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

const shareOnTwitter = () => {
  const text = `Check out this post: ${post.value.title}`
  const url = window.location.href
  window.open(`https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}&url=${encodeURIComponent(url)}`, '_blank')
}

const shareOnFacebook = () => {
  const url = window.location.href
  window.open(`https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(url)}`, '_blank')
}

const copyLink = async () => {
  try {
    await navigator.clipboard.writeText(window.location.href)
    if (window.toast) {
      window.toast.success('Link copied to clipboard!')
    }
  } catch (error) {
    console.error('Failed to copy link:', error)
    if (window.toast) {
      window.toast.error('Failed to copy link')
    }
  }
}

const loadPost = async () => {
  try {
    const result = await postsStore.fetchPost(route.params.slug)
    if (result.success) {
      post.value = result.data
      
      // Update page title
      document.title = `${post.value.title} - BlogCMS`
      
      // Load related posts
      await loadRelatedPosts()
      
      // Track view (only for published posts)
      if (post.value.status === 'published') {
        await trackView()
      }
    } else {
      router.push('/404')
    }
  } catch (error) {
    console.error('Error loading post:', error)
    router.push('/404')
  }
}

const loadRelatedPosts = async () => {
  if (!post.value?.category?.id) return
  
  try {
    const allPosts = await postsStore.fetchPosts({
      category: post.value.category.id,
      status: 'published'
    })
    
    // Filter out current post and limit to 4
    relatedPosts.value = allPosts.data
      .filter(p => p.id !== post.value.id)
      .slice(0, 4)
  } catch (error) {
    console.error('Error loading related posts:', error)
  }
}

const trackView = async () => {
  try {
    await postsStore.trackView(post.value.id)
    if (post.value.views !== undefined) {
      post.value.views = (post.value.views || 0) + 1
    }
  } catch (error) {
    console.error('Error tracking view:', error)
  }
}

// SEO Meta Tags
const updateMetaTags = () => {
  if (!post.value) return
  
  // Remove existing meta tags
  const existingTags = document.querySelectorAll('meta[data-post-meta]')
  existingTags.forEach(tag => tag.remove())
  
  // Add new meta tags
  const metaTags = [
    { name: 'description', content: post.value.excerpt || post.value.title },
    { property: 'og:title', content: post.value.title },
    { property: 'og:description', content: post.value.excerpt || post.value.title },
    { property: 'og:image', content: post.value.featured_image },
    { property: 'og:url', content: window.location.href },
    { property: 'og:type', content: 'article' },
    { name: 'twitter:card', content: 'summary_large_image' },
    { name: 'twitter:title', content: post.value.title },
    { name: 'twitter:description', content: post.value.excerpt || post.value.title },
    { name: 'twitter:image', content: post.value.featured_image }
  ]
  
  metaTags.forEach(tag => {
    if (tag.content) {
      const meta = document.createElement('meta')
      if (tag.name) meta.name = tag.name
      if (tag.property) meta.property = tag.property
      meta.content = tag.content
      meta.setAttribute('data-post-meta', 'true')
      document.head.appendChild(meta)
    }
  })
}

onMounted(() => {
  loadPost()
})

onUnmounted(() => {
  // Clean up meta tags
  const metaTags = document.querySelectorAll('meta[data-post-meta]')
  metaTags.forEach(tag => tag.remove())
  
  // Reset page title
  document.title = 'BlogCMS'
})

// Watch for route changes
watch(() => route.params.slug, () => {
  if (route.params.slug) {
    loadPost()
  }
})

// Update meta tags when post loads
watch(post, () => {
  if (post.value) {
    updateMetaTags()
  }
})
</script>

<style scoped>
/* Custom prose styling */
.prose {
  @apply text-secondary-700;
}

.prose h1,
.prose h2,
.prose h3,
.prose h4,
.prose h5,
.prose h6 {
  @apply text-secondary-900 font-bold;
}

.prose a {
  @apply text-primary-600 no-underline;
}

.prose a:hover {
  @apply text-primary-700 underline;
}

.prose blockquote {
  @apply border-l-4 border-primary-500 bg-primary-50 py-2 px-4 italic;
}

.prose code {
  @apply bg-secondary-100 text-secondary-800 px-1 py-0.5 rounded text-sm;
}

.prose pre {
  @apply bg-secondary-900 text-secondary-100 p-4 rounded-lg overflow-x-auto;
}

.prose pre code {
  @apply bg-transparent text-inherit p-0;
}
</style>
