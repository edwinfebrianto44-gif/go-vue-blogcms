const routes = [
  {
    path: '/',
    name: 'home',
    component: () => import('@/views/HomeView.vue'),
    meta: {
      title: 'Home - Blog CMS',
      prerender: true
    }
  },
  {
    path: '/posts',
    name: 'posts',
    component: () => import('@/views/PostsView.vue'),
    meta: {
      title: 'All Posts - Blog CMS',
      prerender: true
    }
  },
  {
    path: '/posts/:slug',
    name: 'post-detail',
    component: () => import('@/views/PostDetailView.vue'),
    meta: {
      title: 'Post - Blog CMS',
      prerender: true
    }
  },
  {
    path: '/categories/:slug',
    name: 'category-posts',
    component: () => import('@/views/CategoryView.vue'),
    meta: {
      title: 'Category - Blog CMS',
      prerender: true
    }
  },
  {
    path: '/login',
    name: 'login',
    component: () => import('@/views/auth/LoginView.vue'),
    meta: {
      title: 'Login - Blog CMS',
      requiresGuest: true,
      prerender: false
    }
  },
  {
    path: '/register',
    name: 'register',
    component: () => import('@/views/auth/RegisterView.vue'),
    meta: {
      title: 'Register - Blog CMS',
      requiresGuest: true,
      prerender: false
    }
  },
  {
    path: '/dashboard',
    name: 'dashboard',
    component: () => import('@/views/dashboard/DashboardView.vue'),
    meta: {
      title: 'Dashboard - Blog CMS',
      requiresAuth: true,
      prerender: false
    }
  },
  {
    path: '/dashboard/posts',
    name: 'dashboard-posts',
    component: () => import('@/views/dashboard/PostsView.vue'),
    meta: {
      title: 'Manage Posts - Dashboard',
      requiresAuth: true,
      prerender: false
    }
  },
  {
    path: '/dashboard/posts/create',
    name: 'dashboard-posts-create',
    component: () => import('@/views/dashboard/PostForm.vue'),
    meta: {
      title: 'Create Post - Dashboard',
      requiresAuth: true,
      prerender: false
    }
  },
  {
    path: '/dashboard/posts/:id/edit',
    name: 'dashboard-posts-edit',
    component: () => import('@/views/dashboard/PostForm.vue'),
    meta: {
      title: 'Edit Post - Dashboard',
      requiresAuth: true,
      prerender: false
    }
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'not-found',
    component: () => import('@/views/NotFoundView.vue'),
    meta: {
      title: '404 Not Found - Blog CMS',
      prerender: true
    }
  }
]

export default routes
