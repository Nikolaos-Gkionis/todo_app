require 'rails_helper'

RSpec.describe TodosController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:page) { create(:page, user: user) }
  let(:other_page) { create(:page, user: other_user) }
  let(:todo) { create(:todo, page: page) }
  let(:other_todo) { create(:todo, page: other_page) }

  before do
    session[:user_id] = user.id
  end

  describe 'GET #index' do
    it 'redirects to the page' do
      get :index, params: { page_id: page.id }
      expect(response).to redirect_to(page)
    end

    it 'prevents access to other users pages' do
      expect {
        get :index, params: { page_id: other_page.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'requires authentication' do
      session[:user_id] = nil
      get :index, params: { page_id: page.id }
      expect(response).to redirect_to(login_path)
    end
  end

  # Note: GET #new action exists but has no template - todos are created via form on pages/show
  # describe 'GET #new' - Skipped as this action is not used in the current application flow

  describe 'POST #create' do
    let(:valid_todo_params) do
      {
        title: 'New Todo',
        notes: 'Some notes',
        completed: false
      }
    end

    let(:invalid_todo_params) do
      {
        title: '',
        notes: 'A' * 1001
      }
    end

    context 'with valid parameters' do
      it 'creates a new todo' do
        expect {
          post :create, params: { page_id: page.id, todo: valid_todo_params }
        }.to change(Todo, :count).by(1)
      end

      it 'assigns the todo to the page' do
        post :create, params: { page_id: page.id, todo: valid_todo_params }

        todo = Todo.last
        expect(todo.page).to eq(page)
      end

      it 'redirects to page with success message' do
        post :create, params: { page_id: page.id, todo: valid_todo_params }

        expect(response).to redirect_to(page)
        expect(flash[:notice]).to eq('✨ Todo added to Todo-it!')
      end

      it 'sets new todo id in flash for animation' do
        post :create, params: { page_id: page.id, todo: valid_todo_params }

        expect(flash[:new_todo_id]).to eq(Todo.last.id)
      end

      it 'creates todo with correct attributes' do
        post :create, params: { page_id: page.id, todo: valid_todo_params }

        todo = Todo.last
        expect(todo.title).to eq('New Todo')
        expect(todo.notes).to eq('Some notes')
        expect(todo.completed).to be false
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new todo' do
        expect {
          post :create, params: { page_id: page.id, todo: invalid_todo_params }
        }.not_to change(Todo, :count)
      end

      it 'renders pages/show template with errors' do
        post :create, params: { page_id: page.id, todo: invalid_todo_params }

        expect(response).to render_template('pages/show')
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'assigns todos and new_todo for the template' do
        post :create, params: { page_id: page.id, todo: invalid_todo_params }

        expect(assigns(:todos)).to eq(page.todos.ordered.where.not(id: nil))
        expect(assigns(:new_todo)).to eq(assigns(:todo))
      end

      it 'assigns todo with errors' do
        post :create, params: { page_id: page.id, todo: invalid_todo_params }

        expect(assigns(:todo)).to be_a(Todo)
        expect(assigns(:todo)).not_to be_valid
        expect(assigns(:todo).errors).not_to be_empty
      end
    end

    it 'prevents creating todos on other users pages' do
      expect {
        post :create, params: { page_id: other_page.id, todo: valid_todo_params }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'requires authentication' do
      session[:user_id] = nil
      post :create, params: { page_id: page.id, todo: valid_todo_params }
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'GET #edit' do
    it 'renders the edit template' do
      get :edit, params: { page_id: page.id, id: todo.id }
      expect(response).to render_template(:edit)
      expect(response).to have_http_status(:success)
    end

    it 'assigns the correct todo' do
      get :edit, params: { page_id: page.id, id: todo.id }
      expect(assigns(:todo)).to eq(todo)
    end

    it 'prevents access to other users todos' do
      expect {
        get :edit, params: { page_id: other_page.id, id: other_todo.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'requires authentication' do
      session[:user_id] = nil
      get :edit, params: { page_id: page.id, id: todo.id }
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'PATCH #update' do
    let(:valid_update_params) do
      {
        title: 'Updated Todo',
        notes: 'Updated notes',
        completed: true
      }
    end

    let(:invalid_update_params) do
      {
        title: '',
        notes: 'A' * 1001
      }
    end

    context 'with valid parameters' do
      it 'updates the todo' do
        patch :update, params: { page_id: page.id, id: todo.id, todo: valid_update_params }

        todo.reload
        expect(todo.title).to eq('Updated Todo')
        expect(todo.notes).to eq('Updated notes')
        expect(todo.completed).to be true
      end

      it 'redirects to page with success message' do
        patch :update, params: { page_id: page.id, id: todo.id, todo: valid_update_params }

        expect(response).to redirect_to(page)
        expect(flash[:notice]).to eq('Todo was successfully updated.')
      end
    end

    context 'with invalid parameters' do
      it 'does not update the todo' do
        original_title = todo.title
        patch :update, params: { page_id: page.id, id: todo.id, todo: invalid_update_params }

        todo.reload
        expect(todo.title).to eq(original_title)
      end

      it 'renders pages/show template with errors' do
        patch :update, params: { page_id: page.id, id: todo.id, todo: invalid_update_params }

        expect(response).to render_template('pages/show')
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'assigns todos and new_todo for the template' do
        patch :update, params: { page_id: page.id, id: todo.id, todo: invalid_update_params }

        expect(assigns(:todos)).to eq(page.todos.ordered.where.not(id: nil))
        expect(assigns(:new_todo)).to be_a_new(Todo)
      end
    end

    it 'prevents updating other users todos' do
      expect {
        patch :update, params: { page_id: other_page.id, id: other_todo.id, todo: valid_update_params }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'requires authentication' do
      session[:user_id] = nil
      patch :update, params: { page_id: page.id, id: todo.id, todo: valid_update_params }
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the todo' do
      todo_to_delete = create(:todo, page: page)

      expect {
        delete :destroy, params: { page_id: page.id, id: todo_to_delete.id }
      }.to change(Todo, :count).by(-1)
    end

    it 'redirects to page with success message' do
      delete :destroy, params: { page_id: page.id, id: todo.id }

      expect(response).to redirect_to(page)
      expect(flash[:notice]).to eq('Todo was successfully deleted.')
    end

    it 'prevents deleting other users todos' do
      expect {
        delete :destroy, params: { page_id: other_page.id, id: other_todo.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'requires authentication' do
      session[:user_id] = nil
      delete :destroy, params: { page_id: page.id, id: todo.id }
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'POST #reorder' do
    let!(:todo1) { create(:todo, page: page, position: 1) }
    let!(:todo2) { create(:todo, page: page, position: 2) }
    let!(:todo3) { create(:todo, page: page, position: 3) }

    context 'with valid todo IDs' do
      it 'reorders todos successfully' do
        new_order = [ todo3.id, todo1.id, todo2.id ]

        post :reorder, params: { page_id: page.id, todo_ids: new_order }

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to eq({
          'success' => true,
          'message' => 'Todos reordered successfully'
        })
      end

      it 'updates todo positions' do
        new_order = [ todo3.id, todo1.id, todo2.id ]

        post :reorder, params: { page_id: page.id, todo_ids: new_order }

        todo1.reload
        todo2.reload
        todo3.reload

        expect(todo3.position).to eq(1)
        expect(todo1.position).to eq(2)
        expect(todo2.position).to eq(3)
      end
    end

    context 'with empty todo IDs' do
      it 'returns error response' do
        post :reorder, params: { page_id: page.id, todo_ids: [] }

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)).to eq({
          'success' => false,
          'error' => 'No todo IDs provided'
        })
      end
    end

    context 'with nil todo IDs' do
      it 'returns error response' do
        post :reorder, params: { page_id: page.id, todo_ids: nil }

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)).to eq({
          'success' => false,
          'error' => 'No todo IDs provided'
        })
      end
    end

    context 'with invalid todo IDs' do
      it 'handles errors gracefully' do
        post :reorder, params: { page_id: page.id, todo_ids: [ 99999 ] }

        expect(response).to have_http_status(:internal_server_error)
        response_body = JSON.parse(response.body)
        expect(response_body['success']).to be false
        expect(response_body['error']).to be_present
      end
    end

    it 'prevents reordering todos on other users pages' do
      expect {
        post :reorder, params: { page_id: other_page.id, todo_ids: [ other_todo.id ] }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'requires authentication' do
      session[:user_id] = nil
      post :reorder, params: { page_id: page.id, todo_ids: [ todo1.id ] }
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'parameter filtering' do
    it 'only permits allowed parameters' do
      malicious_params = {
        title: 'Test Todo',
        notes: 'Test notes',
        completed: false,
        page_id: other_page.id,
        malicious_field: 'hack_attempt'
      }

      post :create, params: { page_id: page.id, todo: malicious_params }

      todo = Todo.last
      expect(todo.page).to eq(page) # Should not be changed to other_page
      expect(todo.respond_to?(:malicious_field)).to be false
    end
  end

  describe 'user isolation' do
    it 'ensures users can only access their own todos' do
      # Create todos for both users
      user_todo = create(:todo, page: page)
      other_user_todo = create(:todo, page: other_page)

      # User should not be able to access other user's todo
      expect {
        get :edit, params: { page_id: other_page.id, id: other_user_todo.id }
      }.to raise_error(ActiveRecord::RecordNotFound)

      expect {
        patch :update, params: { page_id: other_page.id, id: other_user_todo.id, todo: { title: 'Hacked' } }
      }.to raise_error(ActiveRecord::RecordNotFound)

      expect {
        delete :destroy, params: { page_id: other_page.id, id: other_user_todo.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
