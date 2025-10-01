class Todo < ApplicationRecord
  include DueDateManageable
  include PositionManageable

  belongs_to :page

  validates :title, presence: true, length: { minimum: 1, maximum: 200 }
  validates :page, presence: true

  # Scopes for ordering
  scope :ordered, -> { order(:position) }
  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: false) }

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

  # Class method for reordering todos
  def self.reorder_positions!(page, new_order)
    page.transaction do
      new_order.each_with_index do |item_id, index|
        page.todos.find(item_id).update!(position: index + 1)
      end
    end
  end

  private

  def association_name
    :todos
  end
end
