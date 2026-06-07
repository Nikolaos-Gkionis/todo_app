require 'json'

puts "Loading fake data from db/fake_data.json..."
file_path = Rails.root.join('db', 'fake_data.json')
data = JSON.parse(File.read(file_path))

user_data = data['user']
user = User.find_or_initialize_by(email_address: user_data['email_address'])
user.name = user_data['name']
user.password = user_data['password']
user.password_confirmation = user_data['password'] if user.respond_to?(:password_confirmation=)
# Trial status (when present in fake data)
# Always give the debug user an active trial so login works in local dev
# (hardcoded dates in fake_data.json go stale over time)
user.trial_started_at = Time.current
user.trial_expires_at = 30.days.from_now
if user_data.key?('device_downloaded')
  user.device_downloaded = user_data['device_downloaded']
end
user.save!

puts "Created user: #{user.email_address}"

puts "Cleaning up existing pages and todos for this user to avoid duplicates..."
user.pages.destroy_all
user.todos.where(page_id: nil).destroy_all

puts "Creating pages and lists..."
data['pages'].each do |page_data|
  page = user.pages.create!(
    name: page_data['name'],
    position: page_data['position']
  )

  page_data['todos'].each do |todo_data|
    attrs = {
      title: todo_data['title'],
      completed: todo_data['completed'] || false,
      position: todo_data['position'],
      user_id: user.id,
      notes: todo_data['notes'],
      highlight_color: todo_data['highlight_color']
    }
    attrs[:is_visual_break] = true if todo_data['is_visual_break']
    attrs[:bold] = todo_data['bold'] if todo_data.key?('bold')
    page.todos.create!(attrs)
  end
end

puts "Creating date-based todos..."
data['date_todos'].each do |date_data|
  due_date = Date.parse(date_data['due_date'])

  date_data['todos'].each do |todo_data|
    user.todos.create!(
      title: todo_data['title'],
      completed: todo_data['completed'],
      position: todo_data['position'],
      due_date: due_date,
      highlight_color: todo_data['highlight_color'],
      bold: todo_data['bold'],
      notes: todo_data['notes'],
      recurrence_rule: todo_data['recurrence_rule']
    )
  end
end

puts "Fake data loaded successfully! You can login with:"
puts "Email: #{user.email_address}"
puts "Password: #{user_data['password']}"
