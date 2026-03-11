# frozen_string_literal: true

namespace :polar do
  desc "Create Task Days Download product on Polar (run once per org)"
  task create_product: :environment do
    org_id = ENV["POLAR_ORGANIZATION_ID"]
    if org_id.blank?
      puts "Usage: POLAR_ORGANIZATION_ID=uuid POLAR_ACCESS_TOKEN=xxx bin/rails polar:create_product"
      puts "Get your Organization ID from: https://polar.sh/dashboard (org settings)"
      exit 1
    end
    manager = Polar::ProductManager.new(sandbox: ENV["POLAR_SANDBOX"] == "true")
    result = manager.create_download_product(organization_id: org_id)
    puts "Product created: #{result['id']}"
    puts "Add to .env: POLAR_PRODUCT_ID=#{result['id']}"
  end

  desc "Create 100% test discount (gift code FAMTEST) for local testing"
  task create_test_discount: :environment do
    manager = Polar::ProductManager.new(sandbox: ENV["POLAR_SANDBOX"] == "true")
    result = manager.create_test_discount(organization_id: ENV["POLAR_ORGANIZATION_ID"].presence)
    puts "Discount created: #{result['id']} (code: FAMTEST)"
    puts "Add to .env: POLAR_TEST_DISCOUNT_ID=#{result['id']}"
  end
end
