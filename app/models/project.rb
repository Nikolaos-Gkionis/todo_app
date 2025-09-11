class Project < ApplicationRecord
  belongs_to :user
  has_many :todos, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 1, maximum: 100 }
  validates :description, length: { maximum: 500 }, allow_blank: true
end
