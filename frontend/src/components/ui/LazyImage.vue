<template>
  <div 
    ref="imageContainer"
    :class="[
      'relative overflow-hidden',
      containerClass
    ]"
  >
    <!-- Loading placeholder -->
    <div
      v-if="!imageLoaded && !imageError"
      :class="[
        'absolute inset-0 bg-secondary-200 animate-pulse flex items-center justify-center',
        placeholderClass
      ]"
    >
      <PhotoIcon class="h-8 w-8 text-secondary-400" />
    </div>

    <!-- Error placeholder -->
    <div
      v-if="imageError"
      :class="[
        'absolute inset-0 bg-secondary-100 flex items-center justify-center',
        placeholderClass
      ]"
    >
      <div class="text-center">
        <PhotoIcon class="h-8 w-8 text-secondary-400 mx-auto mb-2" />
        <p class="text-xs text-secondary-500">Failed to load image</p>
      </div>
    </div>

    <!-- Actual image -->
    <img
      v-show="shouldLoad"
      ref="imageRef"
      :src="shouldLoad ? src : undefined"
      :alt="alt"
      :loading="loading"
      :class="[
        'transition-opacity duration-300',
        imageClass,
        {
          'opacity-0': !imageLoaded,
          'opacity-100': imageLoaded
        }
      ]"
      @load="handleLoad"
      @error="handleError"
    />

    <!-- Optional overlay -->
    <div
      v-if="overlay && imageLoaded"
      :class="[
        'absolute inset-0 bg-gradient-to-t from-black/50 to-transparent',
        overlayClass
      ]"
    >
      <slot name="overlay" />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { PhotoIcon } from '@heroicons/vue/24/outline'

const props = defineProps({
  src: {
    type: String,
    required: true
  },
  alt: {
    type: String,
    default: ''
  },
  loading: {
    type: String,
    default: 'lazy',
    validator: (value) => ['lazy', 'eager'].includes(value)
  },
  threshold: {
    type: Number,
    default: 0.1
  },
  rootMargin: {
    type: String,
    default: '50px'
  },
  containerClass: {
    type: String,
    default: ''
  },
  imageClass: {
    type: String,
    default: 'w-full h-full object-cover'
  },
  placeholderClass: {
    type: String,
    default: ''
  },
  overlayClass: {
    type: String,
    default: ''
  },
  overlay: {
    type: Boolean,
    default: false
  },
  eager: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['load', 'error', 'intersect'])

// Refs
const imageContainer = ref(null)
const imageRef = ref(null)
const imageLoaded = ref(false)
const imageError = ref(false)
const shouldLoad = ref(props.eager || props.loading === 'eager')

// Intersection Observer
let observer = null

const handleIntersection = (entries) => {
  const entry = entries[0]
  
  if (entry.isIntersecting) {
    shouldLoad.value = true
    emit('intersect', entry)
    
    // Disconnect observer after first intersection
    if (observer) {
      observer.disconnect()
      observer = null
    }
  }
}

const handleLoad = (event) => {
  imageLoaded.value = true
  emit('load', event)
}

const handleError = (event) => {
  imageError.value = true
  emit('error', event)
}

const setupIntersectionObserver = () => {
  if (!imageContainer.value || shouldLoad.value) return
  
  observer = new IntersectionObserver(handleIntersection, {
    threshold: props.threshold,
    rootMargin: props.rootMargin
  })
  
  observer.observe(imageContainer.value)
}

onMounted(() => {
  // If browser doesn't support IntersectionObserver or eager loading is enabled
  if (!window.IntersectionObserver || props.eager) {
    shouldLoad.value = true
    return
  }
  
  setupIntersectionObserver()
})

onUnmounted(() => {
  if (observer) {
    observer.disconnect()
  }
})
</script>

<style scoped>
/* Ensure the container has a minimum height to trigger intersection observer */
.relative {
  min-height: 1px;
}
</style>
