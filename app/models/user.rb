class User < ApplicationRecord
    has_many :projects, dependent: :destroy

    # Enable secure password functionality
    has_secure_password

    validates :email_address, presence: true, uniqueness: true
    validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }
end
