require 'rails_helper'

RSpec.describe Page, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should belong_to(:user) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:todos).dependent(:destroy) }
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let!(:page1) { create(:page, user: user, position: 1) }
    let!(:page2) { create(:page, user: user, position: 2) }
    let!(:page3) { create(:page, user: user, position: 3) }

    describe '.ordered' do
      it 'returns pages in position order' do
        expect(Page.ordered).to eq([ page1, page2, page3 ])
      end
    end
  end

  describe 'progress calculation' do
    let(:user) { create(:user) }
    let(:page) { create(:page, user: user) }

    context 'when page has no todos' do
      it 'has 0% progress' do
        expect(page.progress_percentage).to eq(0)
      end
    end

    context 'when page has todos' do
      before do
        create(:todo, page: page, completed: true)
        create(:todo, page: page, completed: false)
        create(:todo, page: page, completed: true)
      end

      it 'calculates progress correctly' do
        expect(page.progress_percentage).to eq(67) # 2 out of 3 completed
      end
    end

    context 'when all todos are completed' do
      before do
        create(:todo, page: page, completed: true)
        create(:todo, page: page, completed: true)
      end

      it 'has 100% progress' do
        expect(page.progress_percentage).to eq(100)
      end
    end
  end

  describe 'todo management' do
    let(:user) { create(:user) }
    let(:page) { create(:page, user: user) }

    describe '#completed_todos_count' do
      before do
        create(:todo, page: page, completed: true)
        create(:todo, page: page, completed: false)
        create(:todo, page: page, completed: true)
      end

      it 'returns count of completed todos' do
        expect(page.completed_todos_count).to eq(2)
      end
    end

    describe '#total_todos_count' do
      before do
        create_list(:todo, 3, page: page)
      end

      it 'returns total count of todos' do
        expect(page.total_todos_count).to eq(3)
      end
    end

    describe '#has_todos?' do
      context 'when page has todos' do
        before { create(:todo, page: page) }

        it 'returns true' do
          expect(page.has_todos?).to be true
        end
      end

      context 'when page has no todos' do
        it 'returns false' do
          expect(page.has_todos?).to be false
        end
      end
    end
  end
end
