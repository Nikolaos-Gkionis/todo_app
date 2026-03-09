class PwaController < ApplicationController
  # PWA install is restricted to paid users; trial users get 401
  before_action :ensure_pwa_access!, only: [ :manifest, :service_worker ]
  # Skip default require_login for these actions (we handle auth in ensure_pwa_access!)
  skip_before_action :require_login, only: [ :manifest, :service_worker ]
  # Skip CSRF protection for service worker (it's requested by the browser, not a form submission)
  skip_before_action :verify_authenticity_token, only: [ :service_worker ]

  def manifest
    respond_to do |format|
      format.json { render json: manifest_data }
    end
  end

  def service_worker
    respond_to do |format|
      format.js { render plain: service_worker_content, content_type: "application/javascript" }
    end
  end

  private

  def ensure_pwa_access!
    # Must be logged in and have paid to install PWA
    return head :unauthorized unless logged_in?
    return head :unauthorized unless current_user.can_install_pwa?
  end

  def manifest_data
    {
      name: "Todo-it - Nicely Done ",
      short_name: "Todo-it",
      description: "Beautiful, offline-first todo app. Start with a 7-day free trial, then download forever. Your data, your device.",
      start_url: "/app",
      scope: "/",
      display: "standalone",
      orientation: "portrait-primary",
      theme_color: "#667eea",
      background_color: "#ffffff",
      categories: [ "productivity", "utilities" ],
      lang: "en-US",
      icons: [
        {
          src: "/icon-72.png",
          sizes: "72x72",
          type: "image/png",
          purpose: "any"
        },
        {
          src: "/icon-96.png",
          sizes: "96x96",
          type: "image/png",
          purpose: "any"
        },
        {
          src: "/icon-128.png",
          sizes: "128x128",
          type: "image/png",
          purpose: "any"
        },
        {
          src: "/icon-144.png",
          sizes: "144x144",
          type: "image/png",
          purpose: "any"
        },
        {
          src: "/icon-152.png",
          sizes: "152x152",
          type: "image/png",
          purpose: "any"
        },
        {
          src: "/icon-192.png",
          sizes: "192x192",
          type: "image/png",
          purpose: "any"
        },
        {
          src: "/icon-384.png",
          sizes: "384x384",
          type: "image/png",
          purpose: "any"
        },
        {
          src: "/icon-512.png",
          sizes: "512x512",
          type: "image/png",
          purpose: "any"
        },
        {
          src: "/icon-512-maskable.png",
          sizes: "512x512",
          type: "image/png",
          purpose: "maskable"
        }
      ],
      shortcuts: [
        {
          name: "Add New Page",
          short_name: "New Page",
          description: "Create a new todo page",
          url: "/app/pages/new",
          icons: [
            {
              src: "/icon-96.png",
              sizes: "96x96"
            }
          ]
        },
        {
          name: "View All Pages",
          short_name: "My Pages",
          description: "See all your todo pages",
          url: "/app",
          icons: [
            {
              src: "/icon-96.png",
              sizes: "96x96"
            }
          ]
        },
        {
          name: "Settings",
          short_name: "Settings",
          description: "App settings and preferences",
          url: "/app/settings",
          icons: [
            {
              src: "/icon-96.png",
              sizes: "96x96"
            }
          ]
        }
      ],
      related_applications: [],
      prefer_related_applications: false
    }
  end

  def service_worker_content
    <<~JAVASCRIPT
      const CACHE_NAME = 'todo-it-v1';
      const urlsToCache = [
        '/',
        '/app',
        '/manifest.json',
        '/icon-192.png',
        '/icon-512.png'
      ];

      // Install event - cache resources
      self.addEventListener('install', function(event) {
        event.waitUntil(
          caches.open(CACHE_NAME)
            .then(function(cache) {
              return cache.addAll(urlsToCache);
            })
        );
      });

      // Fetch event - serve from cache when offline
      self.addEventListener('fetch', function(event) {
        event.respondWith(
          caches.match(event.request)
            .then(function(response) {
              // Return cached version or fetch from network
              return response || fetch(event.request);
            }
          )
        );
      });

      // Activate event - clean up old caches
      self.addEventListener('activate', function(event) {
        event.waitUntil(
          caches.keys().then(function(cacheNames) {
            return Promise.all(
              cacheNames.map(function(cacheName) {
                if (cacheName !== CACHE_NAME) {
                  return caches.delete(cacheName);
                }
              })
            );
          })
        );
      });
    JAVASCRIPT
  end
end
