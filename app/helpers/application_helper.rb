module ApplicationHelper
  # Renders an inline SVG icon so it inherits color via currentColor.
  # Use in marketing-icon-circle divs for icons that match the parent text color.
  # Options: :class - additional CSS classes (e.g. "w-5 h-5" for smaller icons)
  def inline_icon(name, options = {})
    path = Rails.root.join("app/assets/images/icons/#{name}.svg")
    return "" unless File.exist?(path)
    svg = File.read(path)
    # Inject width/height so SVG fills the wrapper and scales properly
    svg = svg.sub(/<svg /, '<svg width="100%" height="100%" ')
    size_class = options[:class] || "w-8 h-8"
    # Wrap in span so SVG inherits color from parent (e.g. text-blue-600)
    content_tag(:span, svg.html_safe, class: "inline-flex items-center justify-center #{size_class} flex-shrink-0")
  end
  # Collection of motivational 2-word phrases
  MOTIVATIONAL_PHRASES = [
    "Keep Going",
    "Stay Focused",
    "You Got This",
    "Almost There",
    "Great Work",
    "Stay Strong",
    "Push Forward",
    "Keep Pushing",
    "You're Amazing",
    "Believe Yourself",
    "Never Stop",
    "Dream Big",
    "Stay Positive",
    "Keep Smiling",
    "You Matter",
    "Stay Determined",
    "Keep Shining",
    "You're Capable",
    "Stay Inspired",
    "Keep Growing",
    "You're Powerful",
    "Stay Motivated",
    "Keep Dreaming",
    "You're Special",
    "Stay Confident"
  ].freeze

  # Get a random motivational message
  def random_motivational_message
    MOTIVATIONAL_PHRASES.sample
  end

  # Font stack for preferences (default / serif / sans_serif / system_ui / georgia / menlo)
  def font_stack_for(user)
    return nil unless user

    case user.font_family.to_s
    when "serif"
      "'Lora', Georgia, 'Times New Roman', serif"
    when "sans_serif"
      "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    when "system_ui"
      "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
    when "georgia"
      "Georgia, 'Times New Roman', serif"
    when "menlo"
      "'Menlo', 'Courier New', Courier, monospace"
    else
      nil # default = use body's handwritten font
    end
  end

  # Get current theme from session or default to classic
  def current_theme
    session[:theme] || "classic"
  end

  # Get theme colors for FAB
  def theme_fab_colors(theme = current_theme)
    case theme
    when "classic"
      { background: "linear-gradient(135deg, #3b82f6, #1d4ed8)", border: "#fef3c7" }
    when "lined"
      { background: "linear-gradient(135deg, #ef4444, #dc2626)", border: "#fef3c7" }
    when "graph"
      { background: "linear-gradient(135deg, #16a34a, #15803d)", border: "#fef3c7" }
    when "vintage"
      { background: "linear-gradient(135deg, #b8860b, #a16207)", border: "#fef3c7" }
    when "dark"
      { background: "linear-gradient(135deg, #1f2937, #111827)", border: "#374151" }
    else
      { background: "linear-gradient(135deg, #3b82f6, #1d4ed8)", border: "#fef3c7" }
    end
  end

  # Get theme icon for FAB
  def theme_fab_icon(theme = current_theme)
    case theme
    when "classic"
      "M4 6h16M4 12h16M4 18h16" # hamburger
    when "lined"
      "M4 6h16M4 12h16M4 18h16" # hamburger
    when "graph"
      "M4 6h16M4 12h16M4 18h16" # hamburger
    when "vintage"
      "M4 6h16M4 12h16M4 18h16" # hamburger
    when "dark"
      "M4 6h16M4 12h16M4 18h16" # hamburger
    else
      "M4 6h16M4 12h16M4 18h16" # hamburger
    end
  end
end
