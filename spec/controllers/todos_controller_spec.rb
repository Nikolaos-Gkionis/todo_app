require 'rails_helper'

RSpec.describe TodosController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:page) { create(:page, user: user) }
  let(:todo) { create(:todo, page: page, user: user) }
  let(:other_todo) { create(:todo, user: other_user) }

  before do
    session[:user_id] = user.id
    request.env["HTTP_REFERER"] = app_root_path
  end

  describe 'POST #create' do
    let(:valid_todo_params) do
      {
        title: 'New Todo',
        notes: 'Some notes',
        completed: false,
        page_id: page.id
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
          post :create, params: { todo: valid_todo_params }
        }.to change(Todo, :count).by(1)
      end

      it 'assigns the todo to the page and user' do
        post :create, params: { todo: valid_todo_params }

        new_todo = Todo.last
        expect(new_todo.page).to eq(page)
        expect(new_todo.user).to eq(user)
      end

      it 'redirects back with success message' do
        post :create, params: { todo: valid_todo_params }

        expect(response).to redirect_to(app_root_path)
        expect(flash[:notice]).to eq('Todo added!')
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new todo' do
        expect {
          post :create, params: { todo: invalid_todo_params }
        }.not_to change(Todo, :count)
      end

      it 'redirects back with error message' do
        post :create, params: { todo: invalid_todo_params }

        expect(response).to redirect_to(app_root_path)
        expect(flash[:alert]).to eq('Failed to create todo.')
      end
    end

    it 'requires authentication' do
      session[:user_id] = nil
      post :create, params: { todo: valid_todo_params }
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'PATCH #update' do
    let!(:todo_to_update) { create(:todo, page: page, user: user) }

    let(:valid_update_params) do
      {
        title: 'Updated Todo',
        notes: 'Updated notes',
        completed: true
      }
    end

    context 'with valid parameters' do
      it 'updates the todo' do
        patch :update, params: { id: todo_to_update.id, todo: valid_update_params }

        todo_to_update.reload
        expect(todo_to_update.title).to eq('Updated Todo')
        expect(todo_to_update.notes).to eq('Updated notes')
        expect(todo_to_update.completed).to be true
      end

      it 'redirects back with success message' do
        patch :update, params: { id: todo_to_update.id, todo: valid_update_params }

        expect(response).to redirect_to(app_root_path)
        expect(flash[:notice]).to eq('Todo updated.')
      end
    end

    context 'assigning to page or date' do
      it 'assigns to date if page_id is "null"' do
        patch :update, params: { id: todo_to_update.id, todo: { page_id: "null", due_date: "2024-01-01" } }
        todo_to_update.reload
        expect(todo_to_update.page_id).to be_nil
        expect(todo_to_update.due_date.to_s).to eq("2024-01-01")
      end

      it 'assigns to page if page_id is present' do
        patch :update, params: { id: todo_to_update.id, todo: { page_id: page.id } }
        todo_to_update.reload
        expect(todo_to_update.page_id).to eq(page.id)
        expect(todo_to_update.due_date).to be_nil
      end
    end

    it 'prevents updating other users todos' do
      expect {
        patch :update, params: { id: other_todo.id, todo: valid_update_params }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'requires authentication' do
      session[:user_id] = nil
      patch :update, params: { id: todo_to_update.id, todo: valid_update_params }
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'DELETE #destroy' do
    let!(:todo_to_delete) { create(:todo, page: page, user: user) }

    it 'deletes the todo' do
      expect {
        delete :destroy, params: { id: todo_to_delete.id }
      }.to change(Todo, :count).by(-1)
    end

    it 'redirects back with success message' do
      delete :destroy, params: { id: todo_to_delete.id }

      expect(response).to redirect_to(app_root_path)
      expect(flash[:notice]).to eq('Todo deleted.')
    end

    it 'prevents deleting other users todos' do
      expect {
        delete :destroy, params: { id: other_todo.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'requires authentication' do
      session[:user_id] = nil
      delete :destroy, params: { id: todo_to_delete.id }
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'PATCH #reorder' do
    let!(:todo1) { create(:todo, page: page, user: user, position: 1) }
    let!(:todo2) { create(:todo, page: page, user: user, position: 2) }
    let!(:todo3) { create(:todo, page: page, user: user, position: 3) }

    context 'with valid todo IDs' do
      it 'reorders todos successfully' do
        new_order = [ todo3.id, todo1.id, todo2.id ]

        patch :reorder, params: { todo_ids: new_order }

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to include('success' => true)
      end

      it 'updates todo positions' do
        new_order = [ todo3.id, todo1.id, todo2.id ]

        patch :reorder, params: { todo_ids: new_order }

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
        patch :reorder, params: { todo_ids: [] }

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)).to include('success' => false, 'error' => 'No todo IDs provided')
      end
    end

    it 'prevents reordering other users todos' do
      # Note: Reorder method in the controller silently filters out unowned IDs
      # so it will succeed but not affect the other_todo
      patch :reorder, params: { todo_ids: [ other_todo.id, todo1.id ] }

      todo1.reload
      other_todo.reload

      expect(response).to have_http_status(:success)
      expect(todo1.position).to eq(1)
      expect(other_todo.position).to eq(1) # Assuming other_todo starts at 1
    end

    it 'requires authentication' do
      session[:user_id] = nil
      patch :reorder, params: { todo_ids: [ todo1.id ] }
      expect(response).to redirect_to(login_path)
    end
  end
end
