require 'rails_helper'

RSpec.describe 'Pages and Todos Flow', type: :request do
  let(:user) { create(:user, :with_trial) }
  let(:other_user) { create(:user, :with_trial) }

  before do
    # Log in user
    post login_path, params: { email_address: user.email_address, password: 'password123' }
  end

  describe 'Complete page and todo management flow' do
    it 'allows user to create, manage, and delete pages with todos' do
      # Step 1: Visit pages index
      get app_root_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('My Pages')

      # Step 2: Create a new page
      page_params = {
        page: {
          name: 'Shopping List',
          description: 'Things I need to buy'
        }
      }

      expect {
        post pages_path, params: page_params
      }.to change(Page, :count).by(1)

      # Step 3: Should be redirected to pages index
      expect(response).to redirect_to(pages_path)
      follow_redirect!

      # Step 4: Should be on the pages index page
      expect(response).to have_http_status(:success)
      expect(response.body).to include('My Pages')
      expect(response.body).to include('Shopping List')

      # Step 5: Navigate to the specific page
      page = Page.last
      get page_path(page)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Shopping List')
      expect(response.body).to include('Things I need to buy')

      # Step 6: Add todos to the page
      todo1_params = {
        todo: {
          title: 'Buy milk',
          notes: '2% milk from the store'
        }
      }

      expect {
        post page_todos_path(page), params: todo1_params
      }.to change(Todo, :count).by(1)

      # Step 7: Should be redirected back to page with new todo
      expect(response).to redirect_to(page_path(page))
      follow_redirect!

      # Step 8: Add another todo
      todo2_params = {
        todo: {
          title: 'Buy bread',
          notes: 'Whole wheat bread'
        }
      }

      post page_todos_path(page), params: todo2_params
      expect(response).to redirect_to(page_path(page))

      # Step 9: Verify todos are displayed
      get page_path(page)
      expect(response.body).to include('Buy milk')
      expect(response.body).to include('Buy bread')
      expect(response.body).to include('2% milk from the store')

      # Step 10: Mark first todo as completed
      todo1 = page.todos.find_by(title: 'Buy milk')
      patch page_todo_path(page, todo1), params: { todo: { completed: true } }
      expect(response).to redirect_to(page_path(page))

      # Step 11: Verify todo is marked as completed
      get page_path(page)
      expect(response.body).to include('checked') # Completed todo should have checked attribute

      # Step 12: Edit a todo
      patch page_todo_path(page, todo1), params: {
        todo: {
          title: 'Buy organic milk',
          notes: 'Updated: organic 2% milk'
        }
      }
      expect(response).to redirect_to(page_path(page))

      # Step 13: Verify todo was updated
      get page_path(page)
      expect(response.body).to include('Buy organic milk')
      expect(response.body).to include('Updated: organic 2% milk')

      # Step 14: Delete a todo
      todo2 = page.todos.find_by(title: 'Buy bread')
      expect {
        delete page_todo_path(page, todo2)
      }.to change(Todo, :count).by(-1)

      expect(response).to redirect_to(page_path(page))

      # Step 15: Verify todo was deleted
      get page_path(page)
      expect(response.body).not_to include('Buy bread')

      # Step 16: Edit the page
      patch page_path(page), params: {
        page: {
          name: 'Updated Shopping List',
          description: 'Updated description'
        }
      }
      expect(response).to redirect_to(page_path(page))

      # Step 17: Verify page was updated
      get page_path(page)
      expect(response.body).to include('Updated Shopping List')
      expect(response.body).to include('Updated description')

      # Step 18: Delete the page
      expect {
        delete page_path(page)
      }.to change(Page, :count).by(-1)

      expect(response).to redirect_to(pages_path)

      # Step 19: Verify page was deleted
      get pages_path
      expect(response.body).not_to include('Updated Shopping List')
    end
  end

  describe 'User isolation' do
    it 'prevents users from accessing other users pages and todos' do
      # Create page for other user
      other_page = create(:page, user: other_user, name: 'Other User Page')
      other_todo = create(:todo, page: other_page, title: 'Other User Todo')

      # Step 1: Try to access other user's page
      get page_path(other_page)
      expect(response).to have_http_status(:not_found)

      # Step 2: Try to edit other user's page
      patch page_path(other_page), params: { page: { name: 'Hacked Page' } }
      expect(response).to have_http_status(:not_found)

      # Step 3: Try to delete other user's page
      delete page_path(other_page)
      expect(response).to have_http_status(:not_found)

      # Step 4: Try to access other user's todo
      get edit_page_todo_path(other_page, other_todo)
      expect(response).to have_http_status(:not_found)

      # Step 5: Try to edit other user's todo
      patch page_todo_path(other_page, other_todo), params: { todo: { title: 'Hacked Todo' } }
      expect(response).to have_http_status(:not_found)

      # Step 6: Try to delete other user's todo
      delete page_todo_path(other_page, other_todo)
      expect(response).to have_http_status(:not_found)

      # Step 7: Verify other user's data is unchanged
      other_page.reload
      other_todo.reload
      expect(other_page.name).to eq('Other User Page')
      expect(other_todo.title).to eq('Other User Todo')
    end
  end

  describe 'Todo reordering flow' do
    let(:page) { create(:page, user: user) }

    before do
      # Create multiple todos
      @todo1 = create(:todo, page: page, title: 'First Todo', position: 1)
      @todo2 = create(:todo, page: page, title: 'Second Todo', position: 2)
      @todo3 = create(:todo, page: page, title: 'Third Todo', position: 3)
    end

    it 'allows reordering of todos' do
      # Step 1: Visit page with todos
      get page_path(page)
      expect(response).to have_http_status(:success)

      # Step 2: Reorder todos (move third to first position)
      reorder_params = {
        todo_ids: [ @todo3.id, @todo1.id, @todo2.id ]
      }

      patch reorder_page_todos_path(page), params: reorder_params
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['success']).to be true

      # Step 3: Verify todos were reordered
      @todo1.reload
      @todo2.reload
      @todo3.reload

      expect(@todo3.position).to eq(1)
      expect(@todo1.position).to eq(2)
      expect(@todo2.position).to eq(3)
    end

    it 'handles invalid reorder requests' do
      # Step 1: Try to reorder with empty todo_ids
      patch reorder_page_todos_path(page), params: { todo_ids: [] }
      expect(response).to have_http_status(:internal_server_error)
      expect(JSON.parse(response.body)['success']).to be false

      # Step 2: Try to reorder with non-existent todo IDs
      patch reorder_page_todos_path(page), params: { todo_ids: [ 999, 998 ] }
      expect(response).to have_http_status(:internal_server_error)
      expect(JSON.parse(response.body)['success']).to be false
    end
  end

  describe 'Page and todo validation' do
    it 'handles invalid page creation' do
      # Step 1: Try to create page with invalid data
      invalid_page_params = {
        page: {
          name: '', # Empty name should fail
          description: 'A' * 501 # Too long description should fail
        }
      }

      expect {
        post pages_path, params: invalid_page_params
      }.not_to change(Page, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      # The validation errors are displayed in the form, check for the form being rendered
      expect(response.body).to include('Create New Page')
      expect(response.body).to include('field_with_errors')
    end

    it 'handles invalid todo creation' do
      page = create(:page, user: user)

      # Step 1: Try to create todo with invalid data
      invalid_todo_params = {
        todo: {
          title: '', # Empty title should fail
          notes: 'A' * 1001 # Too long notes should fail
        }
      }

      expect {
        post page_todos_path(page), params: invalid_todo_params
      }.not_to change(Todo, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      # The validation errors are displayed in the form, check for the form being rendered
      expect(response.body).to include('Add New Todo')
      expect(response.body).to include('field_with_errors')
    end
  end
end
