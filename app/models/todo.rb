class Todo < ApplicationRecord
  include PositionManageable

  belongs_to :page

  validates :title, presence: true, length: { minimum: 1, maximum: 200 }
  validates :page, presence: true

  # Simple scopes for ordering
  scope :ordered, -> { order(:position) }
  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: false) }

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
