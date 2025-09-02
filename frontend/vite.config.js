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
    sourcemap: false, // Disable in production for smaller builds
    target: 'es2015', // Support modern browsers
    cssCodeSplit: true,
    assetsInlineLimit: 4096, // Inline small assets
    rollupOptions: {
      output: {
        manualChunks: {
          // Core vendor chunks
          'vendor-vue': ['vue', 'vue-router'],
          'vendor-pinia': ['pinia'],
          'vendor-ui': ['@headlessui/vue', '@heroicons/vue'],
          'vendor-utils': ['axios', 'date-fns'],
        },
        chunkFileNames: (chunkInfo) => {
          // Better chunk naming for caching
          const facadeModuleId = chunkInfo.facadeModuleId
          if (facadeModuleId && facadeModuleId.includes('views/')) {
            return 'views/[name]-[hash].js'
          }
          if (facadeModuleId && facadeModuleId.includes('components/')) {
            return 'components/[name]-[hash].js'
          }
          return 'chunks/[name]-[hash].js'
        },
        assetFileNames: (assetInfo) => {
          // Organize assets by type
          const extType = assetInfo.name.split('.').at(1)
          if (/png|jpe?g|svg|gif|tiff|bmp|ico/i.test(extType)) {
            return `images/[name]-[hash][extname]`
          }
          if (/woff2?|eot|ttf|otf/i.test(extType)) {
            return `fonts/[name]-[hash][extname]`
          }
          if (/css/i.test(extType)) {
            return `css/[name]-[hash][extname]`
          }
          return `assets/[name]-[hash][extname]`
        },
      },
    },
    // Enable modern build features
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true, // Remove console.logs in production
        drop_debugger: true,
        pure_funcs: ['console.log', 'console.info'],
      },
      format: {
        comments: false,
      },
    },
  },
  // SSG Configuration
  ssgOptions: {
    entry: './src/main.ssg.js',
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
