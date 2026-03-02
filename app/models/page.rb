class Page < ApplicationRecord
  include ProgressCalculatable

  belongs_to :user
  has_many :todos, dependent: :destroy

  # Template options: minimal (simple list) or calendar (weekly view)
  TEMPLATES = %w[minimal calendar].freeze

  # Validations
  validates :name, presence: true, length: { minimum: 1, maximum: 100 }
  validates :template, inclusion: { in: TEMPLATES }
  validates :description, length: { maximum: 500 }, allow_blank: true

  # Todo limit checks - all users can add unlimited todos
  def can_add_todo?
    true
  end

  def remaining_todos
    "∞"
  end

  def at_todo_limit?
    false
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
