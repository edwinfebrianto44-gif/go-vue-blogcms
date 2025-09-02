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
