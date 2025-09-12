class Todo < ApplicationRecord
  belongs_to :page

  validates :title, presence: true, length: { minimum: 1, maximum: 200 }
  validates :page, presence: true
  validates :position, presence: true, numericality: { greater_than: 0 }

  # Scopes for ordering
  scope :ordered, -> { order(:position) }
  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: false) }
  
  # Due date scopes
  scope :overdue, -> { where('due_date < ?', Date.current) }
  scope :due_today, -> { where(due_date: Date.current) }
  scope :due_soon, -> { where(due_date: Date.current..3.days.from_now) }
  scope :with_due_dates, -> { where.not(due_date: nil) }
  
  # Smart ordering: overdue first, then due soon, then by position
  scope :ordered_by_priority, -> { 
    order(
      Arel.sql("CASE 
        WHEN due_date IS NOT NULL AND due_date < '#{Date.current}' THEN 1
        WHEN due_date = '#{Date.current}' THEN 2  
        WHEN due_date IS NOT NULL AND due_date <= '#{3.days.from_now.to_date}' THEN 3
        ELSE 4
      END"),
      :due_date,
      :position
    )
  }

  # Set position before validation
  before_validation :set_position, on: :create

  # Method to reorder todos within a page
  def self.reorder_positions!(page, new_order)
    Todo.transaction do
      new_order.each_with_index do |todo_id, index|
        page.todos.find(todo_id).update!(position: index + 1)
      end
    end
  end

  # Method to move todo to a specific position
  def move_to_position!(new_position)
    return if position == new_position

    Todo.transaction do
      if new_position < position
        # Moving up - shift others down
        page.todos.where(position: new_position...position).update_all('position = position + 1')
      else
        # Moving down - shift others up
        page.todos.where(position: (position + 1)..new_position).update_all('position = position - 1')
      end
      
      update!(position: new_position)
    end
  end

  # Due date status methods
  def overdue?
    due_date.present? && due_date < Date.current
  end

  def due_today?
    due_date == Date.current
  end

  def due_soon?
    due_date.present? && due_date.between?(Date.current, 3.days.from_now.to_date)
  end

  def due_status
    return nil unless due_date.present?
    
    if overdue?
      :overdue
    elsif due_today?
      :due_today
    elsif due_soon?
      :due_soon
    else
      :future
    end
  end

  def due_date_display
    return nil unless due_date.present?
    
    case due_status
    when :overdue
      "#{days_overdue} day#{'s' if days_overdue != 1} overdue"
    when :due_today
      "Due today"
    when :due_soon
      "Due in #{days_until_due} day#{'s' if days_until_due != 1}"
    else
      due_date.strftime("%b %d, %Y")
    end
  end

  def due_date_color_class
    case due_status
    when :overdue
      'text-red-600 bg-red-50 border-red-200'
    when :due_today
      'text-orange-600 bg-orange-50 border-orange-200'
    when :due_soon
      'text-green-600 bg-green-50 border-green-200'
    else
      'text-gray-600 bg-gray-50 border-gray-200'
    end
  end

  private

  def days_overdue
    (Date.current - due_date).to_i
  end

  def days_until_due
    (due_date - Date.current).to_i
  end

  def set_position
    return if position.present?
    
    max_position = page.todos.maximum(:position) || 0
    self.position = max_position + 1
  end
end
