import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: false,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['vue', 'vue-router', 'pinia'],
          ui: ['@headlessui/vue', '@heroicons/vue'],
        },
      },
    },
  },
  ssgOptions: {
    script: 'async',
    formatting: 'minify',
    crittersOptions: {
      reduceInlineStyles: false,
    },
    dirStyle: 'nested',
    includeAllRoutes: false,
    routes: [
      '/',
      '/posts',
      '/about',
      '/contact'
    ],
    async onRoutesGenerated(routes, context) {
      // Generate routes for posts and categories dynamically
      const { generateDynamicRoutes } = await import('./src/utils/ssg-routes.js')
      const dynamicRoutes = await generateDynamicRoutes()
      return [...routes, ...dynamicRoutes]
    }
  }
})
