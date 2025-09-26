module PositionManageable
  extend ActiveSupport::Concern

  included do
    validates :position, presence: true, numericality: { greater_than: 0 }
    before_validation :set_position, on: :create
  end

  # Set position before validation
  def set_position
    return if position.present?
    self.position = next_position
  end

  # Get the next position for a new record
  def next_position
    return 1 unless association(:page).loaded? && page.present?
    page.send(association_name).count + 1
  end

  # Move to a specific position
  def move_to_position!(new_position)
    return if position == new_position

    transaction do
      if new_position < position
        # Moving up - shift others down
        shift_items_down(new_position, position - 1)
      else
        # Moving down - shift others up
        shift_items_up(position + 1, new_position)
      end

      update!(position: new_position)
    end
  end

  # Move to the top
  def move_to_top!
    move_to_position!(1)
  end

  # Move to the bottom
  def move_to_bottom!
    max_position = page.send(association_name).count
    move_to_position!(max_position)
  end

  # Move up one position
  def move_up!
    return if position <= 1
    move_to_position!(position - 1)
  end

  # Move down one position
  def move_down!
    max_position = page.send(association_name).count
    return if position >= max_position
    move_to_position!(position + 1)
  end

  # Check if item is at the top
  def at_top?
    position == 1
  end

  # Check if item is at the bottom
  def at_bottom?
    position == page.send(association_name).count
  end

  # Get the item above this one
  def above_item
    return nil if at_top?
    page.send(association_name).find_by(position: position - 1)
  end

  # Get the item below this one
  def below_item
    return nil if at_bottom?
    page.send(association_name).find_by(position: position + 1)
  end

  # Swap positions with another item
  def swap_with!(other_item)
    return if other_item.nil? || other_item == self

    transaction do
      my_position = position
      other_position = other_item.position

      update!(position: other_position)
      other_item.update!(position: my_position)
    end
  end

  # Reorder all items in a page
  def self.reorder_positions!(page, new_order)
    page.transaction do
      new_order.each_with_index do |item_id, index|
        page.send(association_name).find(item_id).update!(position: index + 1)
      end
    end
  end

  private

  def shift_items_down(start_position, end_position)
    page.send(association_name)
         .where(position: start_position..end_position)
         .update_all("position = position + 1")
  end

  def shift_items_up(start_position, end_position)
    page.send(association_name)
         .where(position: start_position..end_position)
         .update_all("position = position - 1")
  end

  def association_name
    # This should be overridden by the including class
    # For example: :todos, :pages, etc.
    raise NotImplementedError, "Classes including PositionManagement must define association_name"
  end
end
