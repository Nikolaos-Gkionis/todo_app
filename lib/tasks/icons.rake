# frozen_string_literal: true

namespace :icons do
  # Tilt: -5 degrees (same as footer/in-app logos). sips -r 355 = 355deg CW = -5deg CCW
  TILT_DEG = "355"

  desc "Generate PWA icons, favicon, and apple-touch-icon (PWA from logo-dark, favicon/apple-touch from logo-light) with -5deg tilt"
  task :generate do
    root = File.expand_path("../..", __dir__)
    src_dark = File.join(root, "app/assets/images/icons/logo-dark.png")
    src_light = File.join(root, "app/assets/images/icons/logo-light.png")
    pub = File.join(root, "public")

    abort "Source logo-dark not found" unless File.exist?(src_dark)
    abort "Source logo-light not found" unless File.exist?(src_light)

    # PWA icons (from logo-dark, -5deg tilt)
    [ 72, 96, 128, 144, 152, 192, 384, 512 ].each do |size|
      out = File.join(pub, "icon-#{size}.png")
      system("sips", "-z", size.to_s, size.to_s, "-r", TILT_DEG, "-o", out, src_dark) || abort("Failed: icon-#{size}.png")
      puts "  Created icon-#{size}.png"
    end

    system("sips", "-z", "512", "512", "-r", TILT_DEG, "-o", File.join(pub, "icon-512-maskable.png"), src_dark) || abort("Failed: icon-512-maskable.png")
    puts "  Created icon-512-maskable.png"

    # Favicon and apple-touch-icon (from logo-light, -5deg tilt)
    system("sips", "-z", "180", "180", "-r", TILT_DEG, "-o", File.join(pub, "apple-touch-icon.png"), src_light) || abort("Failed: apple-touch-icon.png")
    puts "  Created apple-touch-icon.png"

    tmp = File.join(pub, "favicon-temp.png")
    system("sips", "-z", "32", "32", "-r", TILT_DEG, "-o", tmp, src_light) || abort("Failed: favicon")
    File.rename(tmp, File.join(pub, "favicon.ico"))
    puts "  Created favicon.ico"
    puts "Done! All icons written to #{pub} (tilt: -5deg)"
  end
end
