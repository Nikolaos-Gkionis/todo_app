module ApplicationHelper
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
end
