module ProgressCalculatable
  extend ActiveSupport::Concern

  # Calculate completion percentage
  def completion_percentage
    return 0 if total_count == 0
    (completed_count.to_f / total_count * 100).round
  end

  # Generate progress text
  def progress_text
    "#{completed_count}/#{total_count}"
  end

  # Check if progress is complete
  def completed?
    total_count > 0 && completed_count == total_count
  end

  # Check if progress is empty
  def empty?
    total_count == 0
  end

  # Get progress status
  def progress_status
    return :empty if empty?
    return :completed if completed?
    :in_progress
  end

  # Get progress color class for UI
  def progress_color_class
    case progress_status
    when :empty
      "text-gray-500"
    when :completed
      "text-green-600"
    when :in_progress
      "text-blue-600"
    end
  end

  # Get progress bar width for UI
  def progress_bar_width
    "#{completion_percentage}%"
  end

  # Check if progress is at a specific threshold
  def at_threshold?(threshold)
    completion_percentage >= threshold
  end

  # Get progress milestone (25%, 50%, 75%, 100%)
  def progress_milestone
    case completion_percentage
    when 0..24
      :started
    when 25..49
      :quarter
    when 50..74
      :half
    when 75..99
      :three_quarters
    when 100
      :completed
    end
  end

  # Get motivational message based on progress
  def progress_message
    case progress_milestone
    when :started
      "Great start! Keep going! 🚀"
    when :quarter
      "You're making progress! 📈"
    when :half
      "Halfway there! 💪"
    when :three_quarters
      "Almost done! 🎯"
    when :completed
      "All done! 🎉"
    end
  end

  private

  # These methods need to be implemented by the including class
  def total_count
    raise NotImplementedError, "Classes including ProgressCalculation must implement #total_count"
  end

  def completed_count
    raise NotImplementedError, "Classes including ProgressCalculation must implement #completed_count"
  end
end
