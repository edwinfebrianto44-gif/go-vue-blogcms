<template>
  <div class="max-w-4xl mx-auto">
    <!-- Header -->
    <div class="flex items-center justify-between mb-8">
      <div>
        <h1 class="text-2xl font-bold text-secondary-900">
          {{ isEdit ? 'Edit Post' : 'Create New Post' }}
        </h1>
        <p class="text-secondary-600 mt-1">
          {{ isEdit ? 'Update your post content and settings' : 'Write and publish a new post' }}
        </p>
      </div>
      
      <RouterLink
        to="/dashboard/posts"
        class="btn-outline"
      >
        <ArrowLeftIcon class="h-4 w-4 mr-2" />
        Back to Posts
      </RouterLink>
    </div>

    <!-- Form -->
    <form @submit.prevent="handleSubmit" class="space-y-8">
      <!-- Basic Information -->
      <div class="bg-white rounded-lg shadow-sm p-6">
        <h2 class="text-lg font-medium text-secondary-900 mb-6">Basic Information</h2>
        
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <!-- Title -->
          <div class="lg:col-span-2">
            <label for="title" class="label">Title *</label>
            <input
              id="title"
              v-model="form.title"
              type="text"
              required
              class="input"
              :class="{ 'border-red-300 focus:border-red-500 focus:ring-red-500': errors.title }"
              placeholder="Enter post title"
              @input="generateSlug"
            />
            <p v-if="errors.title" class="text-red-600 text-sm mt-1">{{ errors.title }}</p>
          </div>

          <!-- Slug -->
          <div class="lg:col-span-2">
            <label for="slug" class="label">Slug *</label>
            <div class="flex rounded-md shadow-sm">
              <span class="inline-flex items-center px-3 rounded-l-md border border-r-0 border-secondary-300 bg-secondary-50 text-secondary-500 text-sm">
                /posts/
              </span>
              <input
                id="slug"
                v-model="form.slug"
                type="text"
                required
                class="input rounded-l-none"
                :class="{ 'border-red-300 focus:border-red-500 focus:ring-red-500': errors.slug }"
                placeholder="post-slug"
              />
            </div>
            <p v-if="errors.slug" class="text-red-600 text-sm mt-1">{{ errors.slug }}</p>
            <p class="text-secondary-500 text-sm mt-1">URL-friendly version of the title</p>
          </div>

          <!-- Category -->
          <div>
            <label for="category" class="label">Category *</label>
            <select
              id="category"
              v-model="form.category_id"
              required
              class="input"
              :class="{ 'border-red-300 focus:border-red-500 focus:ring-red-500': errors.category_id }"
            >
              <option value="">Select a category</option>
              <option
                v-for="category in categoriesStore.categories"
                :key="category.id"
                :value="category.id"
              >
                {{ category.name }}
              </option>
            </select>
            <p v-if="errors.category_id" class="text-red-600 text-sm mt-1">{{ errors.category_id }}</p>
          </div>

          <!-- Status -->
          <div>
            <label for="status" class="label">Status *</label>
            <select
              id="status"
              v-model="form.status"
              required
              class="input"
            >
              <option value="draft">Draft</option>
              <option value="published">Published</option>
            </select>
          </div>
        </div>

        <!-- Excerpt -->
        <div class="mt-6">
          <label for="excerpt" class="label">Excerpt</label>
          <textarea
            id="excerpt"
            v-model="form.excerpt"
            rows="3"
            class="input"
            placeholder="Brief description of the post (optional)"
          ></textarea>
          <p class="text-secondary-500 text-sm mt-1">
            Short summary that appears in post listings. If left empty, it will be auto-generated from content.
          </p>
        </div>
      </div>

      <!-- Featured Image -->
      <div class="bg-white rounded-lg shadow-sm p-6">
        <h2 class="text-lg font-medium text-secondary-900 mb-6">Featured Image</h2>
        
        <div class="space-y-4">
          <!-- Current Image -->
          <div v-if="form.featured_image" class="relative">
            <img
              :src="form.featured_image"
              :alt="form.title"
              class="w-full h-48 object-cover rounded-lg"
            />
            <button
              type="button"
              @click="form.featured_image = ''"
              class="absolute top-2 right-2 p-1 bg-red-600 text-white rounded-full hover:bg-red-700"
            >
              <XMarkIcon class="h-4 w-4" />
            </button>
          </div>

          <!-- Upload Button -->
          <div v-else class="border-2 border-dashed border-secondary-300 rounded-lg p-8 text-center">
            <PhotoIcon class="mx-auto h-12 w-12 text-secondary-400 mb-4" />
            <p class="text-secondary-600 mb-4">Upload a featured image for your post</p>
            <input
              ref="imageInputRef"
              type="file"
              accept="image/*"
              @change="handleImageUpload"
              class="hidden"
            />
            <button
              type="button"
              @click="$refs.imageInputRef?.click()"
              class="btn-outline"
              :disabled="imageUploading"
            >
              {{ imageUploading ? 'Uploading...' : 'Choose Image' }}
            </button>
          </div>

          <!-- Upload Progress -->
          <div v-if="uploadProgress > 0" class="w-full bg-secondary-200 rounded-full h-2">
            <div
              class="bg-primary-600 h-2 rounded-full transition-all duration-300"
              :style="{ width: uploadProgress + '%' }"
            ></div>
          </div>
        </div>
      </div>

      <!-- Content -->
      <div class="bg-white rounded-lg shadow-sm p-6">
        <h2 class="text-lg font-medium text-secondary-900 mb-6">Content *</h2>
        
        <ContentEditor
          v-model="form.content"
          placeholder="Write your post content here..."
          :height="500"
        />
        <p v-if="errors.content" class="text-red-600 text-sm mt-2">{{ errors.content }}</p>
      </div>

      <!-- SEO Settings -->
      <div class="bg-white rounded-lg shadow-sm p-6">
        <h2 class="text-lg font-medium text-secondary-900 mb-6">SEO Settings</h2>
        
        <div class="space-y-4">
          <!-- Meta Title -->
          <div>
            <label for="meta_title" class="label">Meta Title</label>
            <input
              id="meta_title"
              v-model="form.meta_title"
              type="text"
              class="input"
              placeholder="SEO title (optional)"
            />
            <p class="text-secondary-500 text-sm mt-1">
              If left empty, the post title will be used
            </p>
          </div>

          <!-- Meta Description -->
          <div>
            <label for="meta_description" class="label">Meta Description</label>
            <textarea
              id="meta_description"
              v-model="form.meta_description"
              rows="2"
              class="input"
              placeholder="SEO description (optional)"
            ></textarea>
            <p class="text-secondary-500 text-sm mt-1">
              Brief description for search engines (150-160 characters recommended)
            </p>
          </div>
        </div>
      </div>

      <!-- Actions -->
      <div class="flex items-center justify-between bg-white rounded-lg shadow-sm p-6">
        <div class="flex items-center space-x-4">
          <button
            type="button"
            @click="saveDraft"
            :disabled="postsStore.isLoading"
            class="btn-outline"
          >
            Save as Draft
          </button>
          
          <button
            type="button"
            @click="previewPost"
            class="btn-outline"
          >
            <EyeIcon class="h-4 w-4 mr-2" />
            Preview
          </button>
        </div>

        <div class="flex items-center space-x-4">
          <RouterLink
            to="/dashboard/posts"
            class="text-secondary-600 hover:text-secondary-900"
          >
            Cancel
          </RouterLink>
          
          <button
            type="submit"
            :disabled="postsStore.isLoading"
            class="btn-primary"
          >
            <span v-if="!postsStore.isLoading">
              {{ isEdit ? 'Update Post' : 'Publish Post' }}
            </span>
            <span v-else class="flex items-center">
              <svg class="animate-spin -ml-1 mr-3 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              {{ isEdit ? 'Updating...' : 'Publishing...' }}
            </span>
          </button>
        </div>
      </div>
    </form>

    <!-- Error Message -->
    <div v-if="errorMessage" class="mt-4 bg-red-50 border border-red-200 rounded-md p-4">
      <p class="text-red-600 text-sm">{{ errorMessage }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { RouterLink, useRouter, useRoute } from 'vue-router'
import {
  ArrowLeftIcon,
  XMarkIcon,
  PhotoIcon,
  EyeIcon
} from '@heroicons/vue/24/outline'
import { usePostsStore } from '@/stores/posts'
import { useCategoriesStore } from '@/stores/categories'
import { uploadApi } from '@/services/resources'
import ContentEditor from '@/components/ui/ContentEditor.vue'

const router = useRouter()
const route = useRoute()
const postsStore = usePostsStore()
const categoriesStore = useCategoriesStore()

// Reactive data
const form = reactive({
  title: '',
  slug: '',
  content: '',
  excerpt: '',
  category_id: '',
  status: 'draft',
  featured_image: '',
  meta_title: '',
  meta_description: ''
})

const errors = ref({})
const errorMessage = ref('')
const imageUploading = ref(false)
const uploadProgress = ref(0)
const imageInputRef = ref(null)

// Computed
const isEdit = computed(() => !!route.params.id)
const postId = computed(() => route.params.id)

// Methods
const generateSlug = () => {
  if (!form.title || isEdit.value) return
  
  form.slug = form.title
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .trim()
}

const validateForm = () => {
  errors.value = {}
  
  if (!form.title.trim()) {
    errors.value.title = 'Title is required'
  }
  
  if (!form.slug.trim()) {
    errors.value.slug = 'Slug is required'
  } else if (!/^[a-z0-9-]+$/.test(form.slug)) {
    errors.value.slug = 'Slug can only contain lowercase letters, numbers, and hyphens'
  }
  
  if (!form.content.trim()) {
    errors.value.content = 'Content is required'
  }
  
  if (!form.category_id) {
    errors.value.category_id = 'Category is required'
  }
  
  return Object.keys(errors.value).length === 0
}

const handleSubmit = async () => {
  errorMessage.value = ''
  
  if (!validateForm()) {
    return
  }
  
  const postData = {
    title: form.title.trim(),
    slug: form.slug.trim(),
    content: form.content.trim(),
    excerpt: form.excerpt.trim() || undefined,
    category_id: parseInt(form.category_id),
    status: form.status,
    featured_image: form.featured_image || undefined,
    meta_title: form.meta_title.trim() || undefined,
    meta_description: form.meta_description.trim() || undefined
  }
  
  let result
  if (isEdit.value) {
    result = await postsStore.updatePost(postId.value, postData)
  } else {
    result = await postsStore.createPost(postData)
  }
  
  if (result.success) {
    if (window.toast) {
      window.toast.success(
        'Success!',
        isEdit.value ? 'Post updated successfully!' : 'Post created successfully!'
      )
    }
    router.push('/dashboard/posts')
  } else {
    errorMessage.value = result.message
  }
}

const saveDraft = async () => {
  form.status = 'draft'
  await handleSubmit()
}

const previewPost = () => {
  // Open preview in new tab/window
  if (form.slug) {
    const previewUrl = `/posts/${form.slug}?preview=true`
    window.open(previewUrl, '_blank')
  } else {
    if (window.toast) {
      window.toast.warning('Warning', 'Please enter a slug to preview the post')
    }
  }
}

const handleImageUpload = async (event) => {
  const file = event.target.files[0]
  if (!file) return

  imageUploading.value = true
  uploadProgress.value = 0

  try {
    const result = await uploadApi.uploadImage(file, (progress) => {
      uploadProgress.value = progress
    })

    form.featured_image = result.data.url
    
    if (window.toast) {
      window.toast.success('Success', 'Image uploaded successfully!')
    }
  } catch (error) {
    console.error('Image upload failed:', error)
    if (window.toast) {
      window.toast.error('Error', 'Failed to upload image. Please try again.')
    }
  } finally {
    imageUploading.value = false
    uploadProgress.value = 0
    
    // Reset file input
    if (imageInputRef.value) {
      imageInputRef.value.value = ''
    }
  }
}

const loadPost = async () => {
  if (!isEdit.value) return
  
  try {
    const post = await postsStore.fetchPostById(postId.value)
    
    // Populate form with existing data
    Object.assign(form, {
      title: post.title,
      slug: post.slug,
      content: post.content,
      excerpt: post.excerpt || '',
      category_id: post.category_id,
      status: post.status,
      featured_image: post.featured_image || '',
      meta_title: post.meta_title || '',
      meta_description: post.meta_description || ''
    })
  } catch (error) {
    console.error('Failed to load post:', error)
    if (window.toast) {
      window.toast.error('Error', 'Failed to load post. Please try again.')
    }
    router.push('/dashboard/posts')
  }
}

// Lifecycle
onMounted(async () => {
  // Load categories
  try {
    await categoriesStore.fetchCategories({ limit: 100 })
  } catch (error) {
    console.error('Failed to load categories:', error)
  }
  
  // Load post if editing
  if (isEdit.value) {
    await loadPost()
  }
})
</script>
