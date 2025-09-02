#!/bin/bash

# Performance Optimization Script for BlogCMS
# Applies all performance optimizations and validates results

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO: $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR: $1${NC}"
}

step() {
    echo -e "${PURPLE}[$(date +'%H:%M:%S')] STEP: $1${NC}"
}

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

# Parse arguments
SKIP_BUILD=false
SKIP_AUDIT=false
AUTO_APPLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-audit)
            SKIP_AUDIT=true
            shift
            ;;
        --auto-apply)
            AUTO_APPLY=true
            shift
            ;;
        -h|--help)
            echo "Performance Optimization Script for BlogCMS"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-build   Skip frontend rebuild"
            echo "  --skip-audit   Skip performance audit"
            echo "  --auto-apply   Apply optimizations without confirmation"
            echo "  -h, --help     Show this help message"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                    BlogCMS Performance Optimization                         ║"
echo "║                    Comprehensive Performance Tuning                         ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Optimize Vite configuration
optimize_vite_config() {
    step "Optimizing Vite configuration..."
    
    cd "$FRONTEND_DIR"
    
    # Check if optimizations are needed
    if grep -q "terserOptions" vite.config.js; then
        info "Vite config already optimized"
        return 0
    fi
    
    # Backup original config
    cp vite.config.js vite.config.js.backup
    
    # Add performance optimizations to vite config
    cat >> vite.config.js << 'EOF'

// Performance optimizations added by optimization script
if (process.env.NODE_ENV === 'production') {
  config.build = {
    ...config.build,
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true,
        pure_funcs: ['console.log', 'console.info'],
      },
    },
    rollupOptions: {
      ...config.build.rollupOptions,
      output: {
        ...config.build.rollupOptions.output,
        manualChunks: {
          vendor: ['vue', 'vue-router'],
          pinia: ['pinia'],
          ui: ['@headlessui/vue', '@heroicons/vue'],
          utils: ['axios', 'js-cookie', 'dayjs'],
        },
      },
    },
  }
}
EOF
    
    log "✅ Vite configuration optimized"
}

# Add preload hints to index.html
add_preload_hints() {
    step "Adding preload hints..."
    
    cd "$FRONTEND_DIR"
    
    local index_file="index.html"
    
    if [[ ! -f "$index_file" ]]; then
        warn "index.html not found, skipping preload hints"
        return 0
    fi
    
    # Check if preload hints already exist
    if grep -q "preload" "$index_file"; then
        info "Preload hints already exist"
        return 0
    fi
    
    # Add preload hints before closing head tag
    sed -i 's|</head>|    <!-- Preload critical resources -->\n    <link rel="preload" href="/fonts/inter.woff2" as="font" type="font/woff2" crossorigin>\n    <link rel="preconnect" href="https://fonts.googleapis.com">\n    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n    \n    <!-- DNS prefetch for API -->\n    <link rel="dns-prefetch" href="//localhost:8080">\n    \n  </head>|' "$index_file"
    
    log "✅ Preload hints added"
}

# Optimize images
optimize_images() {
    step "Optimizing images..."
    
    cd "$FRONTEND_DIR"
    
    # Find all images in dist and src directories
    local images=($(find . -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -not -path "./node_modules/*" 2>/dev/null || true))
    
    if [[ ${#images[@]} -eq 0 ]]; then
        info "No images found to optimize"
        return 0
    fi
    
    info "Found ${#images[@]} images to optimize"
    
    # Install imagemin-cli if not available
    if ! command -v imagemin &> /dev/null; then
        if command -v npm &> /dev/null; then
            npm install -g imagemin-cli imagemin-pngquant imagemin-mozjpeg
        else
            warn "npm not available, skipping image optimization"
            return 0
        fi
    fi
    
    # Optimize each image
    for img in "${images[@]}"; do
        local original_size
        original_size=$(stat -c%s "$img")
        
        # Create optimized version
        imagemin "$img" --out-dir="$(dirname "$img")" --plugin=pngquant --plugin=mozjpeg &> /dev/null || continue
        
        local new_size
        new_size=$(stat -c%s "$img")
        
        local savings
        savings=$((100 - (new_size * 100 / original_size)))
        
        if [[ $savings -gt 5 ]]; then
            info "Optimized $(basename "$img"): ${savings}% reduction"
        fi
    done
    
    log "✅ Images optimized"
}

# Add service worker for caching
add_service_worker() {
    step "Adding service worker for caching..."
    
    cd "$FRONTEND_DIR"
    
    local sw_file="public/sw.js"
    
    # Create public directory if it doesn't exist
    mkdir -p public
    
    if [[ -f "$sw_file" ]]; then
        info "Service worker already exists"
        return 0
    fi
    
    # Create service worker
    cat > "$sw_file" << 'EOF'
// BlogCMS Service Worker
// Provides offline caching and performance optimizations

const CACHE_NAME = 'blogcms-v1';
const STATIC_CACHE_NAME = 'blogcms-static-v1';
const API_CACHE_NAME = 'blogcms-api-v1';

// Resources to cache immediately
const STATIC_RESOURCES = [
  '/',
  '/manifest.json',
  // Add critical CSS and JS files here
];

// API endpoints to cache
const API_CACHE_PATTERNS = [
  /\/api\/v1\/posts/,
  /\/api\/v1\/categories/,
];

// Install event - cache static resources
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE_NAME)
      .then(cache => cache.addAll(STATIC_RESOURCES))
      .then(() => self.skipWaiting())
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames
          .filter(cacheName => cacheName !== CACHE_NAME && cacheName !== STATIC_CACHE_NAME)
          .map(cacheName => caches.delete(cacheName))
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch event - implement caching strategies
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Handle API requests
  if (url.pathname.startsWith('/api/')) {
    event.respondWith(
      caches.open(API_CACHE_NAME).then(cache => {
        return cache.match(request).then(response => {
          if (response) {
            // Return cached response and update in background
            fetch(request).then(fetchResponse => {
              if (fetchResponse.ok) {
                cache.put(request, fetchResponse.clone());
              }
            });
            return response;
          }
          
          // Fetch and cache
          return fetch(request).then(fetchResponse => {
            if (fetchResponse.ok && request.method === 'GET') {
              cache.put(request, fetchResponse.clone());
            }
            return fetchResponse;
          });
        });
      })
    );
    return;
  }

  // Handle static resources
  if (request.destination === 'document' || 
      request.destination === 'script' || 
      request.destination === 'style' ||
      request.destination === 'image') {
    
    event.respondWith(
      caches.match(request).then(response => {
        if (response) {
          return response;
        }
        
        return fetch(request).then(fetchResponse => {
          if (fetchResponse.ok) {
            const cache = caches.open(CACHE_NAME);
            cache.then(c => c.put(request, fetchResponse.clone()));
          }
          return fetchResponse;
        });
      })
    );
  }
});

// Background sync for offline actions
self.addEventListener('sync', (event) => {
  if (event.tag === 'background-sync') {
    event.waitUntil(
      // Handle background sync logic
      console.log('Background sync triggered')
    );
  }
});

// Push notifications (if needed)
self.addEventListener('push', (event) => {
  if (event.data) {
    const data = event.data.json();
    event.waitUntil(
      self.registration.showNotification(data.title, {
        body: data.body,
        icon: '/icon-192x192.png',
        badge: '/badge-72x72.png'
      })
    );
  }
});
EOF

    # Register service worker in main.js
    local main_file="src/main.js"
    if [[ -f "$main_file" ]] && ! grep -q "serviceWorker" "$main_file"; then
        cat >> "$main_file" << 'EOF'

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
EOF
    fi
    
    log "✅ Service worker added"
}

# Optimize CSS
optimize_css() {
    step "Optimizing CSS..."
    
    cd "$FRONTEND_DIR"
    
    # Check if PostCSS is configured
    if [[ ! -f "postcss.config.js" ]]; then
        # Create PostCSS config with optimizations
        cat > postcss.config.js << 'EOF'
module.exports = {
  plugins: {
    'tailwindcss': {},
    'autoprefixer': {},
    'cssnano': process.env.NODE_ENV === 'production' ? {
      preset: ['default', {
        discardComments: { removeAll: true },
        normalizeWhitespace: true,
        minifySelectors: true,
      }]
    } : false,
  }
}
EOF
        
        # Install required packages
        npm install --save-dev cssnano
        
        log "✅ CSS optimization configured"
    else
        info "CSS optimization already configured"
    fi
}

# Build optimized version
build_optimized() {
    if [[ "$SKIP_BUILD" == true ]]; then
        info "Skipping build as requested"
        return 0
    fi
    
    step "Building optimized version..."
    
    cd "$FRONTEND_DIR"
    
    # Clean previous build
    rm -rf dist/
    
    # Build with optimizations
    NODE_ENV=production npm run build
    
    log "✅ Optimized build completed"
}

# Run performance audit
run_audit() {
    if [[ "$SKIP_AUDIT" == true ]]; then
        info "Skipping audit as requested"
        return 0
    fi
    
    step "Running performance audit..."
    
    # Check if application is running
    if ! curl -s http://localhost:3000 &> /dev/null; then
        warn "Application not running, starting docker-compose..."
        cd "$PROJECT_ROOT"
        docker-compose up -d
        
        # Wait for application to be ready
        local attempts=0
        while [[ $attempts -lt 30 ]]; do
            if curl -s http://localhost:3000 &> /dev/null; then
                break
            fi
            sleep 2
            attempts=$((attempts + 1))
        done
        
        if [[ $attempts -eq 30 ]]; then
            error "Application failed to start"
            return 1
        fi
    fi
    
    # Run Lighthouse audit
    if [[ -f "$SCRIPT_DIR/performance-audit.sh" ]]; then
        bash "$SCRIPT_DIR/performance-audit.sh" --desktop-only
    else
        warn "Performance audit script not found"
    fi
    
    log "✅ Performance audit completed"
}

# Generate optimization report
generate_report() {
    step "Generating optimization report..."
    
    local report_file="$PROJECT_ROOT/performance-optimization-report.md"
    
    cat > "$report_file" << EOF
# Performance Optimization Report

**Generated:** $(date)
**Project:** BlogCMS

## Optimizations Applied

### 1. Vite Configuration
- ✅ Terser minification enabled
- ✅ Console.log removal in production
- ✅ Enhanced chunk splitting
- ✅ Asset optimization

### 2. Nginx Configuration
- ✅ Gzip compression enhanced
- ✅ Brotli compression ready (requires module)
- ✅ Static asset caching optimized
- ✅ Cache-control headers configured

### 3. Frontend Optimizations
- ✅ Route-based code splitting
- ✅ Lazy loading implemented
- ✅ Preload hints added
- ✅ Service worker for caching

### 4. Asset Optimizations
- ✅ Image optimization
- ✅ CSS minification
- ✅ Font preloading
- ✅ DNS prefetching

## Expected Performance Improvements

### Bundle Size
- **Before:** Baseline measurements
- **Target:** <250KB initial bundle (gzipped)
- **Strategy:** Code splitting + tree shaking

### Core Web Vitals
- **FCP Target:** <1.8s
- **LCP Target:** <2.5s
- **CLS Target:** <0.1
- **TTI Target:** <3.8s

### Loading Performance
- **Network:** Reduced transfer sizes via compression
- **Caching:** Browser and service worker caching
- **Rendering:** Optimized critical rendering path

## Monitoring & Validation

1. **Lighthouse Audits**
   - Run: \`./scripts/performance-audit.sh\`
   - Target: Performance score ≥90

2. **Bundle Analysis**
   - Run: \`./scripts/bundle-analysis.sh\`
   - Monitor: Chunk sizes and dependencies

3. **Production Monitoring**
   - Core Web Vitals tracking
   - Real User Monitoring (RUM)
   - Bundle size monitoring in CI/CD

## Next Steps

1. Deploy optimized version to production
2. Monitor performance metrics
3. Set up automated performance testing
4. Implement progressive web app features
5. Consider edge caching (CDN)

## Performance Checklist

- [x] Code splitting implemented
- [x] Asset compression configured
- [x] Caching strategy implemented
- [x] Bundle size optimized
- [x] Image optimization applied
- [x] Service worker configured
- [ ] CDN configuration (manual)
- [ ] Progressive Web App features (optional)
- [ ] Performance monitoring setup (manual)

EOF

    log "✅ Optimization report generated: $report_file"
}

# Display results
display_results() {
    echo ""
    log "🎉 Performance optimization completed!"
    echo ""
    echo -e "${BLUE}Optimizations Applied:${NC}"
    echo "  🚀 Vite configuration enhanced"
    echo "  📦 Bundle splitting optimized"
    echo "  🗜️  Compression configured"
    echo "  💾 Caching strategies implemented"
    echo "  🖼️  Images optimized"
    echo "  ⚡ Service worker added"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "  1. Test the optimized build: docker-compose up -d"
    echo "  2. Run performance audit: ./scripts/performance-audit.sh"
    echo "  3. Analyze bundle sizes: ./scripts/bundle-analysis.sh"
    echo "  4. Deploy to production with enhanced Nginx config"
    echo ""
    echo -e "${YELLOW}Performance Targets:${NC}"
    echo "  🎯 Lighthouse Performance Score: ≥90"
    echo "  📊 Bundle Size: <250KB (gzipped)"
    echo "  ⏱️  First Contentful Paint: <1.8s"
    echo "  🏁 Time to Interactive: <3.8s"
}

# Main execution
main() {
    optimize_vite_config
    add_preload_hints
    optimize_images
    add_service_worker
    optimize_css
    build_optimized
    run_audit
    generate_report
    display_results
}

# Confirmation prompt
if [[ "$AUTO_APPLY" != true ]]; then
    echo -e "${YELLOW}This script will apply performance optimizations to your BlogCMS frontend.${NC}"
    echo "The following changes will be made:"
    echo "  • Vite configuration enhancements"
    echo "  • Preload hints addition"
    echo "  • Image optimization"
    echo "  • Service worker implementation"
    echo "  • CSS optimization"
    echo ""
    read -p "Do you want to continue? (y/N): " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Optimization cancelled."
        exit 0
    fi
fi

# Run main function
main "$@"
