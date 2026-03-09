class Todo < ApplicationRecord
  include PositionManageable
  belongs_to :user
  belongs_to :page, optional: true

  before_validation :set_user_from_page, on: :create, if: -> { user_id.nil? && page_id.present? }
  before_validation :set_visual_break_title, on: :create

  # Visual break: divider in list, no completion/editing (requires is_visual_break column)
  def is_visual_break?
    return false unless self.class.column_names.include?("is_visual_break")
    is_visual_break == true
  end

  validates :title, presence: true, length: { minimum: 1, maximum: 200 }, unless: :is_visual_break?

  # Simple scopes for ordering
  scope :ordered, -> { order(:position) }
  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: false) }
  scope :for_date, ->(date) { where(due_date: date, page_id: nil) }
  scope :for_page, ->(page_id) { where(page_id: page_id) }

  def assign_to_date(date)
    update(due_date: date, page_id: nil)
  end

  def assign_to_page(page_id)
    update(page_id: page_id, due_date: nil)
  end

  # Class method for reordering todos
  def self.reorder_positions!(new_order)
    transaction do
      new_order.each_with_index do |item_id, index|
        find(item_id).update!(position: index + 1)
      end
    end
  end

  private

  def set_user_from_page
    self.user = page.user if page
  end

  def set_visual_break_title
    self.title = " " if is_visual_break? && title.blank?
  end

  def position_scope
    if page_id.present?
      page.todos
    elsif due_date.present?
      Todo.where(due_date: due_date, page_id: nil)
    else
      Todo.none
    end
  end
end
