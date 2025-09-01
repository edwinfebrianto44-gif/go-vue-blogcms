import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'home',
      component: () => import('@/views/HomeView.vue'),
      meta: {
        title: 'Home - Blog CMS'
      }
    },
    {
      path: '/posts',
      name: 'posts',
      component: () => import('@/views/PostsView.vue'),
      meta: {
        title: 'All Posts - Blog CMS'
      }
    },
    {
      path: '/posts/:slug',
      name: 'post-detail',
      component: () => import('@/views/PostDetailView.vue'),
      meta: {
        title: 'Post - Blog CMS'
      }
    },
    {
      path: '/categories/:slug',
      name: 'category-posts',
      component: () => import('@/views/CategoryView.vue'),
      meta: {
        title: 'Category - Blog CMS'
      }
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/auth/LoginView.vue'),
      meta: {
        title: 'Login - Blog CMS',
        requiresGuest: true
      }
    },
    {
      path: '/register',
      name: 'register',
      component: () => import('@/views/auth/RegisterView.vue'),
      meta: {
        title: 'Register - Blog CMS',
        requiresGuest: true
      }
    },
    {
      path: '/dashboard',
      name: 'dashboard',
      component: () => import('@/views/dashboard/DashboardView.vue'),
      meta: {
        title: 'Dashboard - Blog CMS',
        requiresAuth: true
      }
    },
    {
      path: '/dashboard/posts',
      name: 'dashboard-posts',
      component: () => import('@/views/dashboard/PostsView.vue'),
      meta: {
        title: 'Manage Posts - Dashboard',
        requiresAuth: true
      }
    },
    {
      path: '/dashboard/posts/create',
      name: 'dashboard-posts-create',
      component: () => import('@/views/dashboard/PostForm.vue'),
      meta: {
        title: 'Create Post - Dashboard',
        requiresAuth: true
      }
    },
    {
      path: '/dashboard/posts/:id/edit',
      name: 'dashboard-posts-edit',
      component: () => import('@/views/dashboard/PostForm.vue'),
      meta: {
        title: 'Edit Post - Dashboard',
        requiresAuth: true
      }
    },
    {
      path: '/:pathMatch(.*)*',
      name: 'not-found',
      component: () => import('@/views/NotFoundView.vue'),
      meta: {
        title: '404 Not Found - Blog CMS'
      }
    }
  ],
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) {
      return savedPosition
    } else {
      return { top: 0 }
    }
  }
})

// Navigation guards
router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()
  
  // Initialize auth if not already done
  if (authStore.accessToken && !authStore.user) {
    try {
      await authStore.initAuth()
    } catch (error) {
      console.error('Auth initialization failed:', error)
      authStore.logout()
    }
  }
  
  // Set page title
  document.title = to.meta.title || 'Blog CMS'
  
  // Check authentication requirements
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    // Store intended destination for redirect after login
    const redirectPath = to.fullPath !== '/' ? to.fullPath : null
    next({ 
      name: 'login', 
      query: redirectPath ? { redirect: redirectPath } : {} 
    })
    return
  }
  
  // Check guest requirements (redirect authenticated users)
  if (to.meta.requiresGuest && authStore.isAuthenticated) {
    // Check if there's a stored redirect path
    const redirectPath = localStorage.getItem('redirectPath')
    if (redirectPath && redirectPath !== '/login' && redirectPath !== '/register') {
      localStorage.removeItem('redirectPath')
      next(redirectPath)
    } else {
      next({ name: 'dashboard' })
    }
    return
  }
  
  // Check admin requirements
  if (to.meta.requiresAdmin && (!authStore.isAuthenticated || !authStore.isAdmin)) {
    console.warn('Access denied: Admin privileges required')
    next({ name: 'dashboard' })
    return
  }
  
  // Check editor requirements
  if (to.meta.requiresEditor && (!authStore.isAuthenticated || !authStore.isEditor)) {
    console.warn('Access denied: Editor privileges required')
    next({ name: 'dashboard' })
    return
  }
  
  // Check author requirements
  if (to.meta.requiresAuthor && (!authStore.isAuthenticated || !authStore.isAuthor)) {
    console.warn('Access denied: Author privileges required')
    next({ name: 'dashboard' })
    return
  }
  
  next()
})

export default router
