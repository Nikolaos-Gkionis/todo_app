require 'rails_helper'

RSpec.describe PagesController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:page) { create(:page, user: user) }
  let(:other_page) { create(:page, user: other_user) }

  before do
    session[:user_id] = user.id
  end

  describe 'GET #index' do
    it "redirects to the app root" do
      get :index
      expect(response).to redirect_to(app_root_path)
    end

    it 'requires authentication' do
      session[:user_id] = nil
      get :index
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'GET #show' do
    it 'renders the show template' do
      get :show, params: { id: page.id }
      expect(response).to render_template(:show)
      expect(response).to have_http_status(:success)
    end

    it 'assigns the correct page' do
      get :show, params: { id: page.id }
      expect(assigns(:page)).to eq(page)
    end

    it 'assigns todos in position order' do
      todo1 = create(:todo, page: page, position: 2)
      todo2 = create(:todo, page: page, position: 1)

      get :show, params: { id: page.id }

      expect(assigns(:todos)).to eq([ todo2, todo1 ])
    end

    it 'assigns a new todo for the form' do
      get :show, params: { id: page.id }

      expect(assigns(:new_todo)).to be_a_new(Todo)
      expect(assigns(:new_todo).page).to eq(page)
    end

    it 'prevents access to other users pages' do
      expect {
        get :show, params: { id: other_page.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'requires authentication' do
      session[:user_id] = nil
      get :show, params: { id: page.id }
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'GET #new' do
    it 'renders the new template' do
      get :new
      expect(response).to render_template(:new)
      expect(response).to have_http_status(:success)
    end

    it 'assigns a new page for current user' do
      get :new

      expect(assigns(:page)).to be_a_new(Page)
      expect(assigns(:page).user).to eq(user)
    end

    it 'requires authentication' do
      session[:user_id] = nil
      get :new
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'POST #create' do
    let(:valid_page_params) do
      {
        name: 'My New Page',
        description: 'A test page',
        cover_color: 'blue'
      }
    end

    let(:invalid_page_params) do
      {
        name: '',
        description: 'A' * 501,
        cover_color: 'invalid'
      }
    end

    context 'when user can create pages' do
      before do
        allow(user).to receive(:can_create_page?).and_return(true)
      end

      context 'with valid parameters' do
        it 'creates a new page' do
          expect {
            post :create, params: { page: valid_page_params }
          }.to change(Page, :count).by(1)
        end

        it 'assigns the page to current user' do
          post :create, params: { page: valid_page_params }

          page = Page.last
          expect(page.user).to eq(user)
        end

        it 'redirects to pages index with success message' do
          post :create, params: { page: valid_page_params }

          expect(response).to redirect_to("#{app_root_path}?panel=open")
          expect(flash[:notice]).to eq('Page was successfully created.')
        end

        it 'creates page with correct attributes' do
          post :create, params: { page: valid_page_params }

          page = Page.last
          expect(page.name).to eq('My New Page')
          expect(page.description).to eq('A test page')
          expect(page.cover_color).to eq('blue')
        end
      end

      context 'with invalid parameters' do
        it 'does not create a new page' do
          expect {
            post :create, params: { page: invalid_page_params }
          }.not_to change(Page, :count)
        end

        it 'renders new template with errors' do
          post :create, params: { page: invalid_page_params }

          expect(response).to render_template(:new)
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'assigns page with errors' do
          post :create, params: { page: invalid_page_params }

          expect(assigns(:page)).to be_a(Page)
          expect(assigns(:page)).not_to be_valid
          expect(assigns(:page).errors).not_to be_empty
        end
      end
    end

    context 'when the hosted week has ended' do
      before do
        enable_hosted_ephemeral!
        user.update!(
          trial_started_at: 8.days.ago,
          trial_expires_at: 1.day.ago,
          device_downloaded: false
        )
      end

      it 'does not create a new page' do
        expect {
          post :create, params: { page: valid_page_params }
        }.not_to change(Page, :count)
      end

      it 'redirects home' do
        post :create, params: { page: valid_page_params }

        expect(response).to redirect_to(root_path)
      end
    end


    it 'requires authentication' do
      session[:user_id] = nil
      post :create, params: { page: valid_page_params }
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'GET #edit' do
    it 'renders the edit template' do
      get :edit, params: { id: page.id }
      expect(response).to render_template(:edit)
      expect(response).to have_http_status(:success)
    end

    it 'assigns the correct page' do
      get :edit, params: { id: page.id }
      expect(assigns(:page)).to eq(page)
    end

    it 'prevents access to other users pages' do
      expect {
        get :edit, params: { id: other_page.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'requires authentication' do
      session[:user_id] = nil
      get :edit, params: { id: page.id }
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'PATCH #update' do
    let(:valid_update_params) do
      {
        name: 'Updated Page Name',
        description: 'Updated description',
        cover_color: 'green'
      }
    end

    let(:invalid_update_params) do
      {
        name: '',
        description: 'A' * 501
      }
    end

    context 'with valid parameters' do
      it 'updates the page' do
        patch :update, params: { id: page.id, page: valid_update_params }

        page.reload
        expect(page.name).to eq('Updated Page Name')
        expect(page.description).to eq('Updated description')
        expect(page.cover_color).to eq('green')
      end

      it 'redirects to the page with success message' do
        patch :update, params: { id: page.id, page: valid_update_params }

        expect(response).to redirect_to(page)
        expect(flash[:notice]).to eq('Page was successfully updated.')
      end
    end

    context 'with invalid parameters' do
      it 'does not update the page' do
        original_name = page.name
        patch :update, params: { id: page.id, page: invalid_update_params }

        page.reload
        expect(page.name).to eq(original_name)
      end

      it 'renders edit template with errors' do
        patch :update, params: { id: page.id, page: invalid_update_params }

        expect(response).to render_template(:edit)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'shows error message' do
        patch :update, params: { id: page.id, page: invalid_update_params }

        expect(flash.now[:alert]).to eq('Please fix the errors below.')
      end
    end

    it 'prevents updating other users pages' do
      expect {
        patch :update, params: { id: other_page.id, page: valid_update_params }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'requires authentication' do
      session[:user_id] = nil
      patch :update, params: { id: page.id, page: valid_update_params }
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the page' do
      page_to_delete = create(:page, user: user)

      expect {
        delete :destroy, params: { id: page_to_delete.id }
      }.to change(Page, :count).by(-1)
    end

    it 'redirects to pages index with success message' do
      delete :destroy, params: { id: page.id }

      expect(response).to redirect_to(app_root_path)
      expect(flash[:notice]).to eq('Page was successfully deleted.')
    end

    it 'prevents deleting other users pages' do
      expect {
        delete :destroy, params: { id: other_page.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'requires authentication' do
      session[:user_id] = nil
      delete :destroy, params: { id: page.id }
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'GET #offline' do
    it 'renders offline template without layout' do
      get :offline
      expect(response).to render_template(:offline)
      expect(response).to have_http_status(:success)
    end

    it 'allows access without authentication' do
      session[:user_id] = nil
      get :offline
      expect(response).to have_http_status(:success)
    end
  end

  describe 'parameter filtering' do
    it 'only permits allowed parameters' do
      malicious_params = {
        name: 'Test Page',
        description: 'Test description',
        cover_color: 'blue',
        user_id: other_user.id,
        malicious_field: 'hack_attempt'
      }

      post :create, params: { page: malicious_params }

      page = Page.last
      expect(page.user).to eq(user) # Should not be changed to other_user
      expect(page.respond_to?(:malicious_field)).to be false
    end
  end

  describe 'user isolation' do
    it 'ensures users can only access their own pages' do
      # Create pages for both users
      other_user_page = create(:page, user: other_user)

      # User should not be able to access other user's page
      expect {
        get :show, params: { id: other_user_page.id }
      }.to raise_error(ActiveRecord::RecordNotFound)

      expect {
        get :edit, params: { id: other_user_page.id }
      }.to raise_error(ActiveRecord::RecordNotFound)

      expect {
        patch :update, params: { id: other_user_page.id, page: { name: 'Hacked' } }
      }.to raise_error(ActiveRecord::RecordNotFound)

      expect {
        delete :destroy, params: { id: other_user_page.id }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
