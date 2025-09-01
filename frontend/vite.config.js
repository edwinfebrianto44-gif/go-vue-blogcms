import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
    },
  },
  server: {
    port: 3000,
    host: true,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
        secure: false,
      },
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks(id) {
          // Handle external modules for SSR compatibility
          if (id.includes('node_modules')) {
            if (id.includes('vue') || id.includes('vue-router') || id.includes('pinia')) {
              return 'vendor'
            }
            if (id.includes('@headlessui') || id.includes('@heroicons')) {
              return 'ui'
            }
            return 'vendor'
          }
        },
      },
    },
  },
  // SSG Configuration
  ssgOptions: {
    script: 'async',
    formatting: 'minify',
    crittersOptions: {
      reduceInlineStyles: false,
    },
    includedRoutes(paths, routes) {
      // Include all static routes and dynamic routes for posts/categories
      return paths.filter((i) => !i.includes(':') && !i.includes('*'))
    },
    // Generate dynamic routes for posts and categories
    async onRoutesGenerated(routes) {
      const { generateDynamicRoutes } = await import('./src/utils/ssg-routes.js')
      const dynamicRoutes = await generateDynamicRoutes()
      routes.push(...dynamicRoutes)
      return routes
    },
  },
})
