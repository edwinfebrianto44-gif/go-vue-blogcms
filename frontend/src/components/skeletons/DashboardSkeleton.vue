<template>
  <div class="animate-pulse">
    <!-- Dashboard Header Skeleton -->
    <div class="mb-8">
      <div class="h-8 bg-gray-200 rounded w-48 mb-4"></div>
      <div class="h-4 bg-gray-200 rounded w-64"></div>
    </div>
    
    <!-- Stats Cards Skeleton -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
      <div v-for="i in 4" :key="i" class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center justify-between">
          <div>
            <div class="h-4 bg-gray-200 rounded w-20 mb-2"></div>
            <div class="h-8 bg-gray-200 rounded w-16"></div>
          </div>
          <div class="h-12 w-12 bg-gray-200 rounded-full"></div>
        </div>
      </div>
    </div>
    
    <!-- Recent Activity Section -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
      <!-- Recent Posts -->
      <div class="bg-white rounded-lg shadow">
        <div class="p-6 border-b border-gray-200">
          <div class="h-6 bg-gray-200 rounded w-32"></div>
        </div>
        <div class="p-6">
          <div class="space-y-4">
            <div v-for="i in 5" :key="i" class="flex items-center space-x-4">
              <div class="h-12 w-12 bg-gray-200 rounded"></div>
              <div class="flex-1">
                <div class="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
                <div class="h-3 bg-gray-200 rounded w-1/2"></div>
              </div>
              <div class="h-6 bg-gray-200 rounded-full w-16"></div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Recent Comments -->
      <div class="bg-white rounded-lg shadow">
        <div class="p-6 border-b border-gray-200">
          <div class="h-6 bg-gray-200 rounded w-36"></div>
        </div>
        <div class="p-6">
          <div class="space-y-4">
            <div v-for="i in 5" :key="i" class="flex items-start space-x-4">
              <div class="h-10 w-10 bg-gray-200 rounded-full flex-shrink-0"></div>
              <div class="flex-1">
                <div class="h-3 bg-gray-200 rounded w-1/4 mb-2"></div>
                <div class="h-3 bg-gray-200 rounded w-full mb-1"></div>
                <div class="h-3 bg-gray-200 rounded w-3/4 mb-2"></div>
                <div class="h-3 bg-gray-200 rounded w-1/3"></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Quick Actions -->
    <div class="mt-8">
      <div class="h-6 bg-gray-200 rounded w-32 mb-4"></div>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div v-for="i in 3" :key="i" class="bg-white rounded-lg shadow p-6 text-center">
          <div class="h-12 w-12 bg-gray-200 rounded-full mx-auto mb-4"></div>
          <div class="h-4 bg-gray-200 rounded w-24 mx-auto mb-2"></div>
          <div class="h-3 bg-gray-200 rounded w-32 mx-auto"></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
// Dashboard skeleton loading component
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
