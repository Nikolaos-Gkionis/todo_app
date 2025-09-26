class Page < ApplicationRecord
  include ProgressCalculatable

  belongs_to :user
  has_many :todos, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 1, maximum: 100 }
  validates :description, length: { maximum: 500 }, allow_blank: true

  # Todo limit checks for free users
  def can_add_todo?
    return true if user.premium?
    todos.count < User::MAX_FREE_TODOS_PER_PAGE
  end

  def remaining_todos
    return "∞" if user.premium?
    [ User::MAX_FREE_TODOS_PER_PAGE - todos.count, 0 ].max
  end

  def at_todo_limit?
    return false if user.premium?
    todos.count >= User::MAX_FREE_TODOS_PER_PAGE
  end

  # Todo statistics methods
  def total_todos_count
    total_count
  end

  def completed_todos_count
    completed_count
  end

  def incomplete_todos_count
    todos.where(completed: false).count
  end

  def completion_percentage
    super # Call the concern method
  end

  def progress_text
    super # Call the concern method
  end

  private

  def total_count
    todos.count
  end

  def completed_count
    todos.where(completed: true).count
  end
end
