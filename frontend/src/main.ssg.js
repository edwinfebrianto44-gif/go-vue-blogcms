import { ViteSSG } from 'vite-ssg'
import { createPinia } from 'pinia'
import { createHead } from '@vueuse/head'
import App from './App.vue'
import routes from './router/routes'
import './style.css'

export const createApp = ViteSSG(
  App,
  { 
    routes,
    scrollBehavior(to, from, savedPosition) {
      if (savedPosition) {
        return savedPosition
      } else {
        return { top: 0 }
      }
    }
  },
  ({ app, router, routes, isClient, initialState }) => {
    // Install plugins
    const pinia = createPinia()
    const head = createHead()
    
    app.use(pinia)
    app.use(head)
    
    if (isClient) {
      // Client-side only initialization
      pinia.state.value = initialState.pinia || {}
      
      // Initialize auth store
      import('./stores/auth').then(({ useAuthStore }) => {
        const authStore = useAuthStore()
        authStore.initAuth().catch((error) => {
          console.error('Failed to initialize auth:', error)
        })
      })
      
      // Global toast
      app.config.globalProperties.$toast = {
        success: (title, message) => console.log('Success:', title, message),
        error: (title, message) => console.error('Error:', title, message),
        warning: (title, message) => console.warn('Warning:', title, message)
      }
      
      window.toast = app.config.globalProperties.$toast
    } else {
      // Server-side only initialization
      initialState.pinia = pinia.state.value
    }
  }
)
