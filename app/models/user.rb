class User < ApplicationRecord
    has_many :pages, dependent: :destroy

    # Enable secure password functionality
    has_secure_password

    validates :email_address, presence: true, uniqueness: true
    validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }

    # Freemium limits
    MAX_FREE_PAGES = 3
    MAX_FREE_TODOS_PER_PAGE = 20

    # Premium status helpers
    def premium?
      premium
    end

    def free?
      !premium?
    end

    # Check if user can create more pages
    def can_create_page?
      return true if premium?
      pages.count < MAX_FREE_PAGES
    end

    # Get remaining page slots for free users
    def remaining_pages
      return "∞" if premium?
      [ MAX_FREE_PAGES - pages.count, 0 ].max
    end

    # Check if user can access premium themes
    def can_use_premium_themes?
      premium?
    end
end
