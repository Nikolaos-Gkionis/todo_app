class DownloadsController < ApplicationController
  # Allow token-based access when user clicks from email (e.g. different device)
  skip_before_action :require_login, if: :token_provided?
  before_action :set_user
  before_action :authenticate_user_or_token!

  # Show download page with instructions
  def show
    unless @user.trial_active? || @user.device_downloaded?
      flash[:error] = "You need an active trial or downloaded app to access this page."
      redirect_to app_root_path
      return
    end

    # Generate download token if not exists
    @download_token = @user.download_token || @user.generate_download_token!
  end

  # Download the app bundle (supports token auth for email link clicks)
  def download
    Rails.logger.info "Download requested for user #{@user.id} with token: #{params[:token]}"

    unless @user.trial_active? || @user.device_downloaded?
      Rails.logger.info "User does not have active trial or downloaded app"
      flash[:error] = "You need an active trial or downloaded app to download."
      redirect_to app_root_path
      return
    end

    # Check download limit (3 devices max)
    unless @user.can_download?
      Rails.logger.info "User has reached download limit: #{@user.download_count}/#{User::MAX_DOWNLOADS}"
      flash[:error] = "You've reached the maximum of #{User::MAX_DOWNLOADS} downloads. Each device gets its own independent copy."
      redirect_to download_path(token: params[:token])
      return
    end

    # Verify download token
    unless params[:token] == @user.download_token
      Rails.logger.info "Invalid download token. Expected: #{@user.download_token}, Got: #{params[:token]}"
      flash[:error] = "Invalid download token."
      redirect_to app_root_path
      return
    end

    # Increment download count
    @user.increment_download_count!
    Rails.logger.info "Download count incremented to: #{@user.download_count}"

    # If user already has downloaded app, just create the bundle
    if @user.device_downloaded?
      create_pwa_bundle
      return
    end

    # If user is on trial, redirect to payment first
    if @user.on_trial?
      flash[:info] = "Complete your purchase to download the app to your device."
      redirect_to pricing_path
    end
  end

  private

  def create_pwa_bundle
    Rails.logger.info "Creating PWA bundle for user #{@user.id}"

    begin
      # Create a ZIP file containing the PWA files
      require "zip"

      zip_data = Zip::OutputStream.write_buffer do |zip|
        # Add a simple HTML file
        zip.put_next_entry("index.html")
        zip.write(create_simple_html)

        # Add the manifest file
        zip.put_next_entry("manifest.json")
        zip.write(create_manifest_json)

        # Add the service worker
        zip.put_next_entry("service-worker.js")
        zip.write(File.read(Rails.root.join("app/views/pwa/service-worker.js")))

        # Add CSS files (simplified version)
        zip.put_next_entry("styles.css")
        zip.write(File.read(Rails.root.join("app/assets/stylesheets/application.css")))

        # Add a README with installation instructions
        zip.put_next_entry("README.txt")
        zip.write(create_installation_instructions)

        # Add user's data if they have any
        if @user.pages.any?
          zip.put_next_entry("user-data.json")
          zip.write(DataExportService.export_user_data(@user))
        end
      end

      # Track download success analytics
      AnalyticsService.track_download_success(@user, params[:token])

      # Send the ZIP file
      Rails.logger.info "Sending ZIP file, size: #{zip_data.string.length} bytes"
      send_data zip_data.string,
                filename: "peponito-app-#{@user.id}-#{Time.current.strftime('%Y%m%d-%H%M%S')}.zip",
                type: "application/zip",
                disposition: "attachment"
    rescue => e
      Rails.logger.error "PWA bundle creation failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      flash[:error] = "Download failed. Please try again or contact support."
      redirect_to app_root_path
    end
  end

  def create_simple_html
    <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Peponi.to - Offline App</title>
        <link rel="manifest" href="manifest.json">
        <link rel="stylesheet" href="styles.css">
        <meta name="theme-color" content="#ffffff">
      </head>
      <body class="notebook-background handwritten" id="app-body">
        <div class="container px-4 py-8 mt-4">
          <h1 class="text-3xl font-bold mb-6">Peponi.to Offline App</h1>
          <p class="text-gray-600 mb-4">This is your offline Peponi.to app. Your data has been included in this bundle.</p>
      #{'    '}
          <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
            <h2 class="text-lg font-semibold text-blue-900 mb-2">📱 Installation Instructions</h2>
            <p class="text-blue-800 mb-2">To install this app on your device:</p>
            <ul class="text-blue-800 list-disc list-inside space-y-1">
              <li><strong>Mobile:</strong> Open this file in your browser, then "Add to Home Screen"</li>
              <li><strong>Desktop:</strong> Open this file in your browser, then click the install icon</li>
            </ul>
          </div>

          <div class="bg-green-50 border border-green-200 rounded-lg p-4">
            <h2 class="text-lg font-semibold text-green-900 mb-2">✅ Your Data</h2>
            <p class="text-green-800">Your todo data has been included in this app bundle. Once installed, you can use the app completely offline.</p>
          </div>
        </div>

        <script>
          // Register service worker
          if ('serviceWorker' in navigator) {
            navigator.serviceWorker.register('service-worker.js')
              .then(registration => console.log('SW registered'))
              .catch(error => console.log('SW registration failed'));
          }
        </script>
      </body>
      </html>
    HTML
  end

  def create_manifest_json
    <<~JSON
      {
        "name": "Peponi.to - Organise Your Days",
        "short_name": "Peponi.to",
        "description": "Beautiful, offline-first todo app. Your data, your device.",
        "start_url": "./index.html",
        "scope": "./",
        "display": "standalone",
        "orientation": "portrait-primary",
        "theme_color": "#ffffff",
        "background_color": "#ffffff",
        "categories": ["productivity", "utilities"],
        "lang": "en-US",
        "icons": [
          {
            "src": "/icon-192.png",
            "sizes": "192x192",
            "type": "image/png",
            "purpose": "any"
          },
          {
            "src": "/icon-512.png",
            "sizes": "512x512",
            "type": "image/png",
            "purpose": "any"
          }
        ]
      }
    JSON
  end

  def create_installation_instructions
    <<~INSTRUCTIONS
      Peponi.to PWA Installation Instructions
      =====================================

      This is your personal Peponi.to app bundle. Follow these steps to install it on your device:

      MOBILE DEVICES (iOS/Android):
      1. Extract this ZIP file to a folder on your device
      2. Open the index.html file in your mobile browser
      3. Look for "Add to Home Screen" in your browser menu
      4. Tap "Add" to install the app on your home screen
      5. Launch Peponi.to from your home screen

      DESKTOP (Chrome/Edge/Safari):
      1. Extract this ZIP file to a folder on your computer
      2. Open the index.html file in your browser
      3. Look for the install icon in your browser's address bar
      4. Click "Install" when prompted
      5. Launch Peponi.to from your applications or desktop

      OFFLINE USAGE:
      - The app works completely offline once installed
      - Your data is stored locally on your device
      - No internet connection required after installation

      DATA RESTORATION:
      - If you have a user-data.json file, your data will be automatically restored
      - You can also import data manually through the app's settings

      SUPPORT:
      If you need help, contact us at support@peponi.to

      Enjoy your offline Peponi.to experience!
    INSTRUCTIONS
  end

  # Generate new download token
  def generate_token
    unless @user.trial_active? || @user.device_downloaded?
      flash[:error] = "You need an active trial or downloaded app to generate a download token."
      redirect_to app_root_path
      return
    end

    @download_token = @user.generate_download_token!
    flash[:success] = "New download token generated."
    redirect_to download_path
  end

  # Mark app as downloaded (for testing purposes)
  def mark_downloaded
    unless @user.trial_active?
      flash[:error] = "You need an active trial to mark as downloaded."
      redirect_to app_root_path
      return
    end

    @user.mark_as_downloaded!
    flash[:success] = "App marked as downloaded! You now have full access to all features."
    redirect_to app_root_path
  end

  private

  def token_provided?
    params[:token].present?
  end

  # Allow access via session (logged in) or valid download token (email link)
  def authenticate_user_or_token!
    return if @user.present?

    if params[:token].present?
      flash[:error] = "Invalid or expired download link. Please sign in or request a new link from the app."
    else
      flash_login_required
    end
    redirect_to login_path
  end

  def set_user
    @user = if logged_in?
      current_user
    elsif params[:token].present?
      User.find_by(download_token: params[:token])
    end
  end
end
