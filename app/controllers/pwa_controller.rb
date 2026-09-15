class PwaController < ApplicationController
  # Manifest & service worker only for users who may install (paid / legacy device_downloaded).
  # Matches layout: trial users get no manifest link, no SW registration, no Apple standalone metas.
  before_action :ensure_logged_in_for_pwa!, only: [ :manifest, :service_worker ]
  skip_before_action :block_expired_trial_without_purchase!, only: [ :manifest, :service_worker ]
  skip_before_action :require_login, only: [ :manifest, :service_worker ]
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

  def ensure_logged_in_for_pwa!
    head :unauthorized unless logged_in? && current_user.can_install_pwa?
  end

  def manifest_data
    base = request.base_url
    icon = "#{base}#{helpers.asset_path("peponito.png")}"
    {
      name: "Peponi.to",
      short_name: "Peponi.to",
      description: "Organise tasks by day. Try 7 days free on the web, then pay once to install.",
      start_url: "#{base}/app",
      scope: "#{base}/",
      display_override: [ "fullscreen", "standalone" ],
      display: "standalone",
      orientation: "portrait-primary",
      theme_color: "#ffffff",
      background_color: "#ffffff",
      categories: [ "productivity", "utilities" ],
      lang: "en-US",
      icons: [
        { src: icon, sizes: "192x192", type: "image/png", purpose: "any" },
        { src: icon, sizes: "512x512", type: "image/png", purpose: "any" },
        { src: icon, sizes: "512x512", type: "image/png", purpose: "maskable" }
      ],
      shortcuts: [
        { name: "New list", short_name: "New list", description: "Create a Not Yet list",
          url: "#{base}/app/pages/new", icons: [ { src: icon, sizes: "192x192" } ] },
        { name: "Open planner", short_name: "Planner", description: "Your days and lists",
          url: "#{base}/app", icons: [ { src: icon, sizes: "192x192" } ] },
        { name: "Settings", short_name: "Settings", description: "App settings and preferences",
          url: "#{base}/app/settings", icons: [ { src: icon, sizes: "192x192" } ] }
      ],
      related_applications: [],
      prefer_related_applications: false
    }
  end

  def service_worker_content
    icon_path = helpers.asset_path("peponito.png")
    <<~JAVASCRIPT
      const CACHE_NAME = 'peponito-v1';
      const urlsToCache = [
        '/',
        '/app',
        '/manifest.json',
        '#{icon_path}'
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
