<template>
  <div class="animate-pulse">
    <!-- Post Header Skeleton -->
    <div class="mb-6">
      <div class="h-8 bg-gray-200 rounded-md w-3/4 mb-4"></div>
      <div class="flex items-center space-x-4 mb-4">
        <div class="h-10 w-10 bg-gray-200 rounded-full"></div>
        <div class="space-y-2">
          <div class="h-4 bg-gray-200 rounded w-32"></div>
          <div class="h-3 bg-gray-200 rounded w-24"></div>
        </div>
      </div>
      <div class="h-64 bg-gray-200 rounded-lg mb-4"></div>
    </div>
    
    <!-- Content Skeleton -->
    <div class="space-y-4">
      <div class="h-4 bg-gray-200 rounded w-full"></div>
      <div class="h-4 bg-gray-200 rounded w-5/6"></div>
      <div class="h-4 bg-gray-200 rounded w-4/5"></div>
      <div class="h-4 bg-gray-200 rounded w-full"></div>
      <div class="h-4 bg-gray-200 rounded w-3/4"></div>
      
      <div class="h-6 bg-gray-200 rounded w-1/2 mt-8 mb-4"></div>
      <div class="h-4 bg-gray-200 rounded w-full"></div>
      <div class="h-4 bg-gray-200 rounded w-4/5"></div>
      <div class="h-4 bg-gray-200 rounded w-5/6"></div>
    </div>
    
    <!-- Tags Skeleton -->
    <div class="flex space-x-2 mt-6">
      <div class="h-6 bg-gray-200 rounded-full w-16"></div>
      <div class="h-6 bg-gray-200 rounded-full w-20"></div>
      <div class="h-6 bg-gray-200 rounded-full w-18"></div>
    </div>
    
    <!-- Comments Section Skeleton -->
    <div class="mt-12 pt-8 border-t border-gray-200">
      <div class="h-6 bg-gray-200 rounded w-32 mb-6"></div>
      
      <!-- Comment Form Skeleton -->
      <div class="mb-8">
        <div class="h-32 bg-gray-200 rounded-lg mb-4"></div>
        <div class="h-10 bg-gray-200 rounded w-24"></div>
      </div>
      
      <!-- Comments Skeleton -->
      <div class="space-y-6">
        <div v-for="i in 3" :key="i" class="flex space-x-4">
          <div class="h-10 w-10 bg-gray-200 rounded-full flex-shrink-0"></div>
          <div class="flex-1">
            <div class="h-4 bg-gray-200 rounded w-32 mb-2"></div>
            <div class="space-y-2">
              <div class="h-3 bg-gray-200 rounded w-full"></div>
              <div class="h-3 bg-gray-200 rounded w-4/5"></div>
            </div>
            <div class="h-3 bg-gray-200 rounded w-20 mt-3"></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
// Post detail skeleton loading component
</script>

<style scoped>
@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.7;
  }
}

.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

.animate-pulse > * {
  background-color: #f3f4f6;
  background-image: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.4), transparent);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}

@keyframes shimmer {
  0% {
    background-position: -200% 0;
  }
  100% {
    background-position: 200% 0;
  }
}
</style>
