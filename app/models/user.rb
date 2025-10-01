class User < ApplicationRecord
    include TrialManageable

    has_many :pages, dependent: :destroy

    # Enable secure password functionality
    has_secure_password

    validates :email_address, presence: true, uniqueness: true
    validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :name, presence: true, length: { minimum: 2, maximum: 50 }, on: :create
    validates :name, length: { minimum: 2, maximum: 50 }, allow_blank: true, on: :update
    validates :password, length: { minimum: 6 }, on: :create


    # Display name for the user (name if available, otherwise email)
    def display_name
      name.presence || email_address
    end
end
