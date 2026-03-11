// Task Days Progressive Web App Service Worker
// Handles offline functionality, caching, and background sync

const CACHE_NAME = 'todo-it-v1.0.13';
const STATIC_CACHE = 'todo-it-static-v1.0.13';
const DYNAMIC_CACHE = 'todo-it-dynamic-v1.0.13';

// Static assets to cache immediately
const STATIC_ASSETS = [
  '/',
  '/app',
  '/offline',
  '/assets/application.css',
  '/assets/application.js',
  '/manifest.json'
];

// Install event - cache static assets
self.addEventListener('install', event => {
  console.log('[Service Worker] Installing...');
  event.waitUntil(
    caches.open(STATIC_CACHE)
      .then(cache => {
        console.log('[Service Worker] Caching static assets...');
        return cache.addAll(STATIC_ASSETS);
      })
      .catch(error => {
        console.error('[Service Worker] Cache installation failed:', error);
      })
  );
  self.skipWaiting();
});

// Activate event - clean up old caches
self.addEventListener('activate', event => {
  console.log('[Service Worker] Activating...');
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== STATIC_CACHE && cacheName !== DYNAMIC_CACHE) {
            console.log('[Service Worker] Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    })
  );
  self.clients.claim();
});

// Fetch event - handle requests with different strategies
self.addEventListener('fetch', event => {
  const { request } = event;
  const url = new URL(request.url);

  // Skip non-GET requests
  if (request.method !== 'GET') return;

  // Skip external requests
  if (!url.origin.includes(self.location.origin)) return;

  // Handle API requests (network-first strategy)
  if (url.pathname.startsWith('/app/')) {
    event.respondWith(networkFirstStrategy(request));
    return;
  }

  // Handle static assets (cache-first strategy)
  if (url.pathname.match(/\.(css|js|png|jpg|jpeg|gif|svg|ico|woff|woff2|ttf|eot)$/)) {
    event.respondWith(cacheFirstStrategy(request));
    return;
  }

  // Default: network-first with cache fallback
  event.respondWith(networkFirstStrategy(request));
});

// Cache-first strategy for static assets
async function cacheFirstStrategy(request) {
  try {
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }

    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(STATIC_CACHE);
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    console.error('[Service Worker] Cache-first strategy failed:', error);
    return caches.match('/offline');
  }
}

// Network-first strategy for dynamic content
async function networkFirstStrategy(request) {
  try {
    const networkResponse = await fetch(request);

    // Cache successful responses
    if (networkResponse.ok) {
      const cache = await caches.open(DYNAMIC_CACHE);
      cache.put(request, networkResponse.clone());
    }

    return networkResponse;
  } catch (error) {
    console.log('[Service Worker] Network request failed, trying cache:', error);

    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }

    // Return offline page for navigation requests
    if (request.mode === 'navigate') {
      return caches.match('/offline');
    }

    return new Response('Offline', { status: 503, statusText: 'Service Unavailable' });
  }
}

// Background sync for offline actions
self.addEventListener('sync', event => {
  console.log('[Service Worker] Background sync triggered:', event.tag);

  if (event.tag === 'todo-sync') {
    event.waitUntil(syncTodos());
  }

  if (event.tag === 'page-sync') {
    event.waitUntil(syncPages());
  }
});

// Sync todos when back online
async function syncTodos() {
  try {
    // Get pending todos from IndexedDB (would be implemented in the app)
    const pendingTodos = await getPendingTodosFromIndexedDB();

    for (const todo of pendingTodos) {
      await fetch('/app/todos', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': await getCsrfToken()
        },
        body: JSON.stringify(todo)
      });
    }

    // Clear synced todos from IndexedDB
    await clearSyncedTodosFromIndexedDB();

    // Notify user of successful sync
    self.registration.showNotification('Task Days Sync Complete', {
      body: 'Your offline changes have been synced successfully!',
      icon: '/icon-192.png',
      badge: '/icon-192.png'
    });
  } catch (error) {
    console.error('[Service Worker] Todo sync failed:', error);
  }
}

// Sync pages when back online
async function syncPages() {
  try {
    const pendingPages = await getPendingPagesFromIndexedDB();

    for (const page of pendingPages) {
      await fetch('/app/pages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': await getCsrfToken()
        },
        body: JSON.stringify(page)
      });
    }

    await clearSyncedPagesFromIndexedDB();

    self.registration.showNotification('Page Sync Complete', {
      body: 'Your offline pages have been synced!',
      icon: '/icon-192.png',
      badge: '/icon-192.png'
    });
  } catch (error) {
    console.error('[Service Worker] Page sync failed:', error);
  }
}

// Push notification handling
self.addEventListener('push', event => {
  if (!event.data) return;

  try {
    const data = event.data.json();
    const options = {
      body: data.body,
      icon: '/icon-192.png',
      badge: '/icon-192.png',
      data: {
        path: data.path || '/app'
      }
    };

    event.waitUntil(
      self.registration.showNotification(data.title || 'Task Days', options)
    );
  } catch (error) {
    console.error('[Service Worker] Push notification error:', error);
  }
});

// Notification click handling
self.addEventListener('notificationclick', event => {
  event.notification.close();

  event.waitUntil(
    clients.matchAll({ type: 'window' }).then(clientList => {
      const path = event.notification.data?.path || '/app';

      // Check if app is already open
      for (let client of clientList) {
        if (new URL(client.url).pathname === path && 'focus' in client) {
          return client.focus();
        }
      }

      // Open new window if app isn't open
      if (clients.openWindow) {
        return clients.openWindow(path);
      }
    })
  );
});

// Helper functions (would be implemented based on app's IndexedDB usage)
async function getPendingTodosFromIndexedDB() {
  // Implementation would depend on the app's IndexedDB setup
  return [];
}

async function getPendingPagesFromIndexedDB() {
  // Implementation would depend on the app's IndexedDB setup
  return [];
}

async function clearSyncedTodosFromIndexedDB() {
  // Implementation would depend on the app's IndexedDB setup
}

async function clearSyncedPagesFromIndexedDB() {
  // Implementation would depend on the app's IndexedDB setup
}

async function getCsrfToken() {
  // Get CSRF token from meta tag or other source
  return '';
}
