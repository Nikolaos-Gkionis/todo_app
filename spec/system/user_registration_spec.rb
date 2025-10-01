require 'rails_helper'

RSpec.describe 'User Registration', type: :system do
  scenario 'user can sign up and start trial' do
    visit root_path

    # Click sign up button
    click_link 'Start Free Trial'

    # Fill out registration form
    fill_in 'Name', with: 'John Doe'
    fill_in 'Email', with: 'john@example.com'
    fill_in 'Password', with: 'password123'
    fill_in 'Password confirmation', with: 'password123'

    # Submit form
    click_button 'Create Account'

    # Should be redirected to app
    expect(page).to have_current_path(app_root_path)
    expect(page).to have_content('7-day free trial has started')

    # Should be logged in
    expect(page).to have_content('John Doe')
    expect(page).to have_content('Free Trial: 7 days remaining')
  end

  scenario 'user sees validation errors with invalid data' do
    visit signup_path

    # Submit empty form
    click_button 'Create Account'

    # Should see validation errors
    expect(page).to have_content("Name can't be blank")
    expect(page).to have_content("Email can't be blank")
    expect(page).to have_content("Password can't be blank")
  end

  scenario 'user cannot sign up with duplicate email' do
    create(:user, email: 'existing@example.com')

    visit signup_path

    fill_in 'Name', with: 'John Doe'
    fill_in 'Email', with: 'existing@example.com'
    fill_in 'Password', with: 'password123'
    fill_in 'Password confirmation', with: 'password123'

    click_button 'Create Account'

    expect(page).to have_content('Email has already been taken')
  end
end
