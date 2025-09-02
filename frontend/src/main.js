import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { createHead } from '@vueuse/head'
import App from './App.vue'
import router from './router'
import { useAuthStore } from './stores/auth'
import './style.css'

const app = createApp(App)
const pinia = createPinia()
const head = createHead()

app.use(pinia)
app.use(router)
app.use(head)

// Initialize auth store
const authStore = useAuthStore()
authStore.initAuth().catch((error) => {
  console.error('Failed to initialize auth:', error)
})

// Global error handler
app.config.errorHandler = (err, instance, info) => {
  console.error('Global error:', err, info)
}

// Global properties
app.config.globalProperties.$toast = {
  success: (title, message) => {
    console.log('Success:', title, message)
    // You can integrate with a toast library here
  },
  error: (title, message) => {
    console.error('Error:', title, message)
    // You can integrate with a toast library here
  },
  warning: (title, message) => {
    console.warn('Warning:', title, message)
    // You can integrate with a toast library here
  }
}

// Make toast available globally
window.toast = app.config.globalProperties.$toast

app.mount('#app')

// Register service worker
if ('serviceWorker' in navigator && process.env.NODE_ENV === 'production') {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js')
      .then(registration => {
        console.log('SW registered: ', registration);
      })
      .catch(registrationError => {
        console.log('SW registration failed: ', registrationError);
      });
  });
}
