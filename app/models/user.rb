class User < ApplicationRecord
    has_many :projects, dependent: :destroy

    validates :email_address, presence: true, uniqueness: true
    validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }
end
