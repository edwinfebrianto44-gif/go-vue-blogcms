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
      component: () => import('@/views/CategoryPostsView.vue'),
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
      component: () => import('@/views/dashboard/DashboardLayout.vue'),
      meta: {
        title: 'Dashboard - Blog CMS',
        requiresAuth: true
      },
      children: [
        {
          path: '',
          name: 'dashboard-home',
          component: () => import('@/views/dashboard/DashboardHome.vue'),
          meta: {
            title: 'Dashboard - Blog CMS',
            requiresAuth: true
          }
        },
        {
          path: 'posts',
          name: 'dashboard-posts',
          component: () => import('@/views/dashboard/PostsManagement.vue'),
          meta: {
            title: 'Manage Posts - Dashboard',
            requiresAuth: true
          }
        },
        {
          path: 'posts/create',
          name: 'dashboard-posts-create',
          component: () => import('@/views/dashboard/PostForm.vue'),
          meta: {
            title: 'Create Post - Dashboard',
            requiresAuth: true
          }
        },
        {
          path: 'posts/:id/edit',
          name: 'dashboard-posts-edit',
          component: () => import('@/views/dashboard/PostForm.vue'),
          meta: {
            title: 'Edit Post - Dashboard',
            requiresAuth: true
          }
        },
        {
          path: 'categories',
          name: 'dashboard-categories',
          component: () => import('@/views/dashboard/CategoriesManagement.vue'),
          meta: {
            title: 'Manage Categories - Dashboard',
            requiresAuth: true,
            requiresAdmin: true
          }
        },
        {
          path: 'comments',
          name: 'dashboard-comments',
          component: () => import('@/views/dashboard/CommentsManagement.vue'),
          meta: {
            title: 'Manage Comments - Dashboard',
            requiresAuth: true
          }
        },
        {
          path: 'profile',
          name: 'dashboard-profile',
          component: () => import('@/views/dashboard/ProfileSettings.vue'),
          meta: {
            title: 'Profile Settings - Dashboard',
            requiresAuth: true
          }
        }
      ]
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
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()
  
  // Set page title
  document.title = to.meta.title || 'Blog CMS'
  
  // Check authentication requirements
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next({ name: 'login', query: { redirect: to.fullPath } })
    return
  }
  
  // Check guest requirements (redirect authenticated users)
  if (to.meta.requiresGuest && authStore.isAuthenticated) {
    next({ name: 'dashboard' })
    return
  }
  
  // Check admin requirements
  if (to.meta.requiresAdmin && (!authStore.isAuthenticated || !authStore.isAdmin)) {
    next({ name: 'dashboard' })
    return
  }
  
  next()
})

export default router
