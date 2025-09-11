class Todo < ApplicationRecord
  belongs_to :project

  validates :title, presence: true, length: { minimum: 1, maximum: 200 }
  validates :project, presence: true
  validates :position, presence: true, numericality: { greater_than: 0 }

  # Scopes for ordering
  scope :ordered, -> { order(:position) }
  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: false) }

  # Set position before creating
  before_create :set_position

  # Method to reorder todos within a project
  def self.reorder_positions!(project, new_order)
    Todo.transaction do
      new_order.each_with_index do |todo_id, index|
        project.todos.find(todo_id).update!(position: index + 1)
      end
    end
  end

  # Method to move todo to a specific position
  def move_to_position!(new_position)
    return if position == new_position

    Todo.transaction do
      if new_position < position
        # Moving up - shift others down
        project.todos.where(position: new_position...position).update_all('position = position + 1')
      else
        # Moving down - shift others up
        project.todos.where(position: (position + 1)..new_position).update_all('position = position - 1')
      end
      
      update!(position: new_position)
    end
  end

  private

  def set_position
    return if position.present?
    
    max_position = project.todos.maximum(:position) || 0
    self.position = max_position + 1
  end
end
