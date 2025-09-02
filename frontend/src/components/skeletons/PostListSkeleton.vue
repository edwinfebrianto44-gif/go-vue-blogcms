<template>
  <div class="space-y-6">
    <!-- Header Skeleton -->
    <div class="mb-8">
      <div class="h-10 bg-gray-200 rounded-md w-64 mb-4 animate-pulse"></div>
      <div class="h-4 bg-gray-200 rounded w-96 animate-pulse"></div>
    </div>
    
    <!-- Filter/Search Skeleton -->
    <div class="flex justify-between items-center mb-6">
      <div class="flex space-x-4">
        <div class="h-10 bg-gray-200 rounded-lg w-32 animate-pulse"></div>
        <div class="h-10 bg-gray-200 rounded-lg w-24 animate-pulse"></div>
      </div>
      <div class="h-10 bg-gray-200 rounded-lg w-64 animate-pulse"></div>
    </div>
    
    <!-- Post Cards Skeleton -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div v-for="i in 6" :key="i" class="animate-pulse">
        <div class="bg-white rounded-lg shadow-md overflow-hidden">
          <!-- Image Skeleton -->
          <div class="h-48 bg-gray-200"></div>
          
          <!-- Content Skeleton -->
          <div class="p-6">
            <!-- Category Badge -->
            <div class="h-6 bg-gray-200 rounded-full w-20 mb-3"></div>
            
            <!-- Title -->
            <div class="h-6 bg-gray-200 rounded w-full mb-3"></div>
            <div class="h-6 bg-gray-200 rounded w-3/4 mb-4"></div>
            
            <!-- Excerpt -->
            <div class="space-y-2 mb-4">
              <div class="h-4 bg-gray-200 rounded w-full"></div>
              <div class="h-4 bg-gray-200 rounded w-5/6"></div>
              <div class="h-4 bg-gray-200 rounded w-4/5"></div>
            </div>
            
            <!-- Meta Info -->
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-3">
                <div class="h-8 w-8 bg-gray-200 rounded-full"></div>
                <div>
                  <div class="h-3 bg-gray-200 rounded w-20 mb-1"></div>
                  <div class="h-3 bg-gray-200 rounded w-16"></div>
                </div>
              </div>
              <div class="h-8 bg-gray-200 rounded w-20"></div>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Pagination Skeleton -->
    <div class="flex justify-center mt-12">
      <div class="flex space-x-2">
        <div class="h-10 w-10 bg-gray-200 rounded animate-pulse"></div>
        <div class="h-10 w-10 bg-gray-200 rounded animate-pulse"></div>
        <div class="h-10 w-10 bg-gray-200 rounded animate-pulse"></div>
        <div class="h-10 w-10 bg-gray-200 rounded animate-pulse"></div>
        <div class="h-10 w-10 bg-gray-200 rounded animate-pulse"></div>
      </div>
    </div>
  </div>
</template>

<script setup>
// Posts list skeleton loading component
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
