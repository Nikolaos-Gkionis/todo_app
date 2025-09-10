class Todo < ApplicationRecord
  belongs_to :project

  validates :title, presence: true, length: { minimum: 1, maximum: 200 }
  validates :project, presence: true
end
