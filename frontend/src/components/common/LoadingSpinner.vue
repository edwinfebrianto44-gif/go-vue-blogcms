<template>
  <div
    v-if="isLoading"
    class="loading-overlay"
    :class="{ 'fade-in': isLoading, 'fade-out': !isLoading }"
  >
    <div class="loading-container">
      <!-- Spinner -->
      <div class="spinner">
        <div class="spinner-ring"></div>
        <div class="spinner-ring"></div>
        <div class="spinner-ring"></div>
        <div class="spinner-ring"></div>
      </div>
      
      <!-- Loading Text -->
      <div class="loading-text">
        {{ loadingText }}
      </div>
      
      <!-- Progress Bar (optional) -->
      <div v-if="showProgress" class="progress-container">
        <div 
          class="progress-bar"
          :style="{ width: `${progress}%` }"
        ></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  isLoading: {
    type: Boolean,
    default: false
  },
  loadingText: {
    type: String,
    default: 'Loading...'
  },
  showProgress: {
    type: Boolean,
    default: false
  },
  progress: {
    type: Number,
    default: 0
  },
  overlay: {
    type: Boolean,
    default: true
  }
})

// Prevent body scroll when loading overlay is active
onMounted(() => {
  if (props.isLoading && props.overlay) {
    document.body.style.overflow = 'hidden'
  }
})

onUnmounted(() => {
  document.body.style.overflow = ''
})

// Watch for loading state changes
watch(() => props.isLoading, (newVal) => {
  if (props.overlay) {
    document.body.style.overflow = newVal ? 'hidden' : ''
  }
})
</script>

<style scoped>
.loading-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(255, 255, 255, 0.9);
  backdrop-filter: blur(8px);
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease-in-out;
}

.loading-container {
  text-align: center;
  padding: 2rem;
  background: white;
  border-radius: 1rem;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
  max-width: 300px;
  width: 90%;
}

.spinner {
  position: relative;
  width: 60px;
  height: 60px;
  margin: 0 auto 1.5rem;
}

.spinner-ring {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  border: 3px solid transparent;
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 1.2s cubic-bezier(0.5, 0, 0.5, 1) infinite;
}

.spinner-ring:nth-child(1) {
  animation-delay: -0.45s;
}

.spinner-ring:nth-child(2) {
  animation-delay: -0.3s;
  border-top-color: #10b981;
}

.spinner-ring:nth-child(3) {
  animation-delay: -0.15s;
  border-top-color: #f59e0b;
}

.spinner-ring:nth-child(4) {
  border-top-color: #ef4444;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

.loading-text {
  font-size: 1.1rem;
  font-weight: 500;
  color: #374151;
  margin-bottom: 1rem;
}

.progress-container {
  width: 100%;
  height: 4px;
  background: #e5e7eb;
  border-radius: 2px;
  overflow: hidden;
}

.progress-bar {
  height: 100%;
  background: linear-gradient(90deg, #3b82f6, #10b981);
  border-radius: 2px;
  transition: width 0.3s ease;
}

.fade-in {
  opacity: 1;
  transform: scale(1);
}

.fade-out {
  opacity: 0;
  transform: scale(0.95);
}

/* Reduced motion for accessibility */
@media (prefers-reduced-motion: reduce) {
  .spinner-ring {
    animation: none;
  }
  
  .loading-overlay {
    transition: none;
  }
  
  .spinner {
    background: #3b82f6;
    border-radius: 50%;
    width: 40px;
    height: 40px;
  }
  
  .spinner-ring {
    display: none;
  }
}
</style>
