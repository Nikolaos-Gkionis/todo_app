module DueDateManageable
  extend ActiveSupport::Concern

  included do
    # Due date scopes
    scope :overdue, -> { where("due_date < ?", Date.current) }
    scope :due_today, -> { where(due_date: Date.current) }
    scope :due_soon, -> { where(due_date: Date.current..3.days.from_now) }
    scope :with_due_dates, -> { where.not(due_date: nil) }
    scope :without_due_dates, -> { where(due_date: nil) }
  end

  # Due date status methods
  def overdue?
    due_date.present? && due_date < Date.current
  end

  def due_today?
    due_date.present? && due_date == Date.current
  end

  def due_soon?
    due_date.present? && due_date > Date.current && due_date <= 3.days.from_now.to_date
  end

  def has_due_date?
    due_date.present?
  end

  def due_date_status
    return :no_due_date unless has_due_date?
    return :overdue if overdue?
    return :due_today if due_today?
    return :due_soon if due_soon?
    :future
  end

  # Get due date color class for UI
  def due_date_color_class
    case due_date_status
    when :no_due_date
      "text-gray-500"
    when :overdue
      "text-red-600"
    when :due_today
      "text-orange-600"
    when :due_soon
      "text-yellow-600"
    when :future
      "text-blue-600"
    end
  end

  # Get due date background color class for UI
  def due_date_bg_color_class
    case due_date_status
    when :no_due_date
      "bg-gray-100"
    when :overdue
      "bg-red-100"
    when :due_today
      "bg-orange-100"
    when :due_soon
      "bg-yellow-100"
    when :future
      "bg-blue-100"
    end
  end

  # Get due date border color class for UI
  def due_date_border_color_class
    case due_date_status
    when :no_due_date
      "border-gray-200"
    when :overdue
      "border-red-200"
    when :due_today
      "border-orange-200"
    when :due_soon
      "border-yellow-200"
    when :future
      "border-blue-200"
    end
  end

  # Get days until due date
  def days_until_due
    return nil unless has_due_date?
    (due_date - Date.current).to_i
  end

  # Get formatted due date text
  def due_date_text
    return "No due date" unless has_due_date?

    case due_date_status
    when :overdue
      "Overdue by #{-days_until_due} day#{-days_until_due == 1 ? '' : 's'}"
    when :due_today
      "Due today"
    when :due_soon
      "Due in #{days_until_due} day#{days_until_due == 1 ? '' : 's'}"
    when :future
      "Due #{due_date.strftime('%b %d, %Y')}"
    end
  end

  # Get urgency level (1-5, where 5 is most urgent)
  def urgency_level
    return 1 unless has_due_date?
    return 5 if overdue?
    return 4 if due_today?
    return 3 if due_soon?
    return 2 if days_until_due <= 7
    1
  end

  # Check if due date is approaching (within warning period)
  def approaching_due_date?(warning_days = 3)
    has_due_date? && days_until_due <= warning_days && days_until_due >= 0
  end

  # Get due date icon for UI
  def due_date_icon
    case due_date_status
    when :no_due_date
      "📅"
    when :overdue
      "⚠️"
    when :due_today
      "🔥"
    when :due_soon
      "⏰"
    when :future
      "📆"
    end
  end
end
