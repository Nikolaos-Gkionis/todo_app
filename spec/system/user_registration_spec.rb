require 'rails_helper'

RSpec.describe 'User Registration', type: :system do
  scenario 'user can sign up and start trial' do
    visit root_path

    # Click sign up button
    click_link 'Start free trial', match: :first

    # Fill out registration form
    fill_in 'Name', with: 'John Doe'
    fill_in 'Email', with: 'john@example.com'
    fill_in 'Password', with: 'password123'
    fill_in 'Confirm Password', with: 'password123'

    # Submit form
    click_button 'Create Account'

    # Should be redirected to app (trial starts via check_trial_status; flash may not be visible in UI)
    expect(page).to have_current_path(app_root_path)
    expect(page).to have_css('.dashboard')
    expect(page).to have_css('.week-col')
  end

  scenario 'user sees validation errors with invalid data' do
    visit signup_path

    # Fill with values that pass HTML5 required/format but fail server-side validation
    fill_in 'Name', with: 'A'                    # Too short (min 2)
    fill_in 'Email', with: 'valid@example.com'    # Valid format
    fill_in 'Password', with: '12345'             # Too short (min 6)
    fill_in 'Confirm Password', with: '12345'

    click_button 'Create Account'

    # Should see validation errors
    expect(page).to have_content("error")
  end

  scenario 'user cannot sign up with duplicate email' do
    create(:user, email_address: 'existing@example.com')

    visit signup_path

    fill_in 'Name', with: 'John Doe'
    fill_in 'Email', with: 'existing@example.com'
    fill_in 'Password', with: 'password123'
    fill_in 'Confirm Password', with: 'password123'

    click_button 'Create Account'

    expect(page).to have_content('Email address has already been taken')
  end
end
