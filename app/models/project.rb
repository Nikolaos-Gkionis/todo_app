class Project < ApplicationRecord
  belongs_to :user
  has_many :todos, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 1, maximum: 100 }
  validates :description, length: { maximum: 500 }, allow_blank: true

  # Todo statistics methods
  def total_todos_count
    todos.count
  end

  def completed_todos_count
    todos.where(completed: true).count
  end

  def incomplete_todos_count
    todos.where(completed: false).count
  end

  def completion_percentage
    return 0 if total_todos_count == 0
    (completed_todos_count.to_f / total_todos_count * 100).round
  end

  def progress_text
    "#{completed_todos_count}/#{total_todos_count}"
  end
end
