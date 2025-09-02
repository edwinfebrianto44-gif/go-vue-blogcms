import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

// Preload critical components
const HomeView = () => import(/* webpackChunkName: "home" */ '@/views/HomeView.vue')
const PostsView = () => import(/* webpackChunkName: "posts" */ '@/views/PostsView.vue')
const PostDetailView = () => import(/* webpackChunkName: "post-detail" */ '@/views/PostDetailView.vue')

// Lazy load admin components (less critical)
const DashboardView = () => import(/* webpackChunkName: "dashboard" */ '@/views/dashboard/DashboardView.vue')
const DashboardPosts = () => import(/* webpackChunkName: "dashboard-posts" */ '@/views/dashboard/PostsView.vue')
const PostForm = () => import(/* webpackChunkName: "post-form" */ '@/views/dashboard/PostForm.vue')

// Lazy load auth components
const LoginView = () => import(/* webpackChunkName: "auth" */ '@/views/auth/LoginView.vue')
const RegisterView = () => import(/* webpackChunkName: "auth" */ '@/views/auth/RegisterView.vue')

// Lazy load other components
const CategoryView = () => import(/* webpackChunkName: "category" */ '@/views/CategoryView.vue')
const NotFoundView = () => import(/* webpackChunkName: "error" */ '@/views/NotFoundView.vue')

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView,
      meta: {
        title: 'Home - Blog CMS',
        preload: true // Preload this route
      }
    },
    {
      path: '/posts',
      name: 'posts',
      component: PostsView,
      meta: {
        title: 'All Posts - Blog CMS',
        preload: true // Preload this route
      }
    },
    {
      path: '/posts/:slug',
      name: 'post-detail',
      component: PostDetailView,
      meta: {
        title: 'Post - Blog CMS',
        preload: true // Preload this route
      }
    },
    {
      path: '/categories/:slug',
      name: 'category-posts',
      component: CategoryView,
      meta: {
        title: 'Category - Blog CMS'
      }
    },
    {
      path: '/login',
      name: 'login',
      component: LoginView,
      meta: {
        title: 'Login - Blog CMS',
        requiresGuest: true
      }
    },
    {
      path: '/register',
      name: 'register',
      component: RegisterView,
      meta: {
        title: 'Register - Blog CMS',
        requiresGuest: true
      }
    },
    {
      path: '/dashboard',
      name: 'dashboard',
      component: DashboardView,
      meta: {
        title: 'Dashboard - Blog CMS',
        requiresAuth: true
      }
    },
    {
      path: '/dashboard/posts',
      name: 'dashboard-posts',
      component: DashboardPosts,
      meta: {
        title: 'Manage Posts - Dashboard',
        requiresAuth: true
      }
    },
    {
      path: '/dashboard/posts/create',
      name: 'dashboard-posts-create',
      component: PostForm,
      meta: {
        title: 'Create Post - Dashboard',
        requiresAuth: true
      }
    },
    {
      path: '/dashboard/posts/:id/edit',
      name: 'dashboard-posts-edit',
      component: PostForm,
      meta: {
        title: 'Edit Post - Dashboard',
        requiresAuth: true
      }
    },
    {
      path: '/:pathMatch(.*)*',
      name: 'not-found',
      component: NotFoundView,
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

// Route prefetching for better performance
router.afterEach((to) => {
  // Prefetch routes that are likely to be visited next
  const prefetchRoutes = []
  
  switch (to.name) {
    case 'home':
      prefetchRoutes.push('posts', 'post-detail')
      break
    case 'posts':
      prefetchRoutes.push('post-detail', 'category-posts')
      break
    case 'login':
      prefetchRoutes.push('dashboard')
      break
    case 'dashboard':
      prefetchRoutes.push('dashboard-posts')
      break
  }
  
  // Prefetch routes after a short delay to avoid blocking
  setTimeout(() => {
    prefetchRoutes.forEach(routeName => {
      const route = router.getRoutes().find(r => r.name === routeName)
      if (route && route.component) {
        // Trigger dynamic import
        route.component()
      }
    })
  }, 100)
  
  // Update document title
  if (to.meta?.title) {
    document.title = to.meta.title
  }
})

export default router
