<template>
  <div>
    <!-- Hero Section -->
    <section class="bg-gradient-to-r from-primary-600 to-primary-800 text-white">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
        <div class="text-center">
          <h1 class="text-4xl md:text-6xl font-bold mb-6">
            Welcome to <span class="text-gradient-light">BlogCMS</span>
          </h1>
          <p class="text-xl md:text-2xl text-primary-100 mb-8 max-w-3xl mx-auto">
            Discover amazing stories, insights, and knowledge from our community of writers.
          </p>
          <div class="flex flex-col sm:flex-row gap-4 justify-center">
            <RouterLink to="/posts" class="btn bg-white text-primary-600 hover:bg-primary-50 btn-lg">
              Explore Posts
            </RouterLink>
            <RouterLink to="/register" class="btn border-2 border-white text-white hover:bg-white hover:text-primary-600 btn-lg">
              Join Community
            </RouterLink>
          </div>
        </div>
      </div>
    </section>

    <!-- Featured Posts -->
    <section class="py-16 bg-white">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-12">
          <h2 class="text-3xl md:text-4xl font-bold text-secondary-900 mb-4">
            Featured Posts
          </h2>
          <p class="text-lg text-secondary-600 max-w-2xl mx-auto">
            Check out our latest and most popular articles from talented writers.
          </p>
        </div>

        <!-- Loading State -->
        <div v-if="postsStore.isLoading" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          <div v-for="n in 6" :key="n" class="card p-6 animate-pulse">
            <div class="h-48 bg-secondary-200 rounded-md mb-4"></div>
            <div class="h-4 bg-secondary-200 rounded w-3/4 mb-2"></div>
            <div class="h-4 bg-secondary-200 rounded w-1/2 mb-4"></div>
            <div class="h-3 bg-secondary-200 rounded w-full mb-2"></div>
            <div class="h-3 bg-secondary-200 rounded w-2/3"></div>
          </div>
        </div>

        <!-- Posts Grid -->
        <div v-else-if="featuredPosts.length > 0" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          <PostCard
            v-for="post in featuredPosts"
            :key="post.id"
            :post="post"
            class="animate-fade-in"
          />
        </div>

        <!-- Empty State -->
        <div v-else class="text-center py-12">
          <div class="text-secondary-400 mb-4">
            <svg class="h-24 w-24 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
            </svg>
          </div>
          <h3 class="text-lg font-medium text-secondary-900 mb-2">No posts yet</h3>
          <p class="text-secondary-600">Be the first to create a post!</p>
        </div>

        <!-- View All Posts -->
        <div v-if="featuredPosts.length > 0" class="text-center mt-12">
          <RouterLink to="/posts" class="btn-primary btn-lg">
            View All Posts
          </RouterLink>
        </div>
      </div>
    </section>

    <!-- Categories Section -->
    <section class="py-16 bg-secondary-50">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center mb-12">
          <h2 class="text-3xl md:text-4xl font-bold text-secondary-900 mb-4">
            Explore Categories
          </h2>
          <p class="text-lg text-secondary-600 max-w-2xl mx-auto">
            Browse posts by category and find exactly what you're looking for.
          </p>
        </div>

        <!-- Categories Grid -->
        <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
          <RouterLink
            v-for="category in categories"
            :key="category.id"
            :to="`/categories/${category.slug}`"
            class="card p-6 text-center hover:shadow-md transition-shadow group"
          >
            <div class="text-primary-600 mb-3">
              <svg class="h-8 w-8 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"></path>
              </svg>
            </div>
            <h3 class="font-semibold text-secondary-900 group-hover:text-primary-600 transition-colors">
              {{ category.name }}
            </h3>
            <p v-if="category.description" class="text-sm text-secondary-600 mt-1">
              {{ category.description }}
            </p>
          </RouterLink>
        </div>
      </div>
    </section>

    <!-- CTA Section -->
    <section class="py-16 bg-primary-600">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
        <h2 class="text-3xl md:text-4xl font-bold text-white mb-4">
          Ready to Share Your Story?
        </h2>
        <p class="text-xl text-primary-100 mb-8 max-w-2xl mx-auto">
          Join our community of writers and start publishing your thoughts today.
        </p>
        <RouterLink to="/register" class="btn bg-white text-primary-600 hover:bg-primary-50 btn-lg">
          Get Started
        </RouterLink>
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { RouterLink } from 'vue-router'
import { usePostsStore } from '@/stores/posts'
import { useCategoriesStore } from '@/stores/categories'
import { useSEO, createWebsiteJsonLd, createOrganizationJsonLd } from '@/composables/useSEO'
import PostCard from '@/components/PostCard.vue'

const postsStore = usePostsStore()
const categoriesStore = useCategoriesStore()

const featuredPosts = ref([])
const categories = ref([])

// SEO Configuration for Homepage
useSEO({
  title: 'Welcome to Blog CMS',
  description: 'Discover amazing stories, insights, and knowledge from our community of writers. Join our blogging platform and share your thoughts with the world.',
  url: '/',
  type: 'website',
  tags: ['blog', 'cms', 'writing', 'community', 'articles', 'publishing'],
  canonical: '/'
})

onMounted(async () => {
  try {
    // Fetch latest posts (first 6 as featured)
    await postsStore.fetchPosts({ limit: 6 })
    featuredPosts.value = postsStore.posts

    // Fetch categories
    categories.value = await categoriesStore.fetchCategories()
    
    // Add structured data for homepage
    const websiteSchema = createWebsiteJsonLd()
    const organizationSchema = createOrganizationJsonLd()
    
    // Inject JSON-LD into head
    document.head.appendChild(websiteSchema)
    document.head.appendChild(organizationSchema)
    
  } catch (error) {
    console.error('Failed to fetch data:', error)
    if (window.toast) {
      window.toast.error('Error', 'Failed to load content')
    }
  }
})
</script>

<style scoped>
.text-gradient-light {
  @apply bg-gradient-to-r from-white to-primary-100 bg-clip-text text-transparent;
}
</style>
