<template>
  <div id="app" class="min-h-screen bg-secondary-50">
    <!-- Navigation -->
    <AppNavbar />
    
    <!-- Main Content -->
    <main class="pb-16">
      <RouterView />
    </main>
    
    <!-- Footer -->
    <AppFooter />
    
    <!-- Toast Notifications -->
    <ToastContainer />
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { RouterView } from 'vue-router'
import AppNavbar from '@/components/layout/AppNavbar.vue'
import AppFooter from '@/components/layout/AppFooter.vue'
import ToastContainer from '@/components/ui/ToastContainer.vue'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

onMounted(() => {
  // Initialize auth state from localStorage
  authStore.initAuth()
})
</script>
