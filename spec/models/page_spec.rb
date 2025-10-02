require 'rails_helper'

RSpec.describe Page, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:todos).dependent(:destroy) }
  end

  describe 'validations' do
    describe 'name' do
      it { should validate_presence_of(:name) }
      it { should validate_length_of(:name).is_at_least(1).is_at_most(100) }

      it 'rejects empty name' do
        page = build(:page, name: '')
        expect(page).not_to be_valid
        expect(page.errors[:name]).to include("can't be blank")
      end

      it 'rejects name that is too long' do
        page = build(:page, name: 'a' * 101)
        expect(page).not_to be_valid
        expect(page.errors[:name]).to include('is too long (maximum is 100 characters)')
      end
    end

    describe 'description' do
      it 'allows blank description' do
        page = build(:page, description: '')
        expect(page).to be_valid
      end

      it 'allows nil description' do
        page = build(:page, description: nil)
        expect(page).to be_valid
      end

      it 'validates maximum length when present' do
        page = build(:page, description: 'a' * 501)
        expect(page).not_to be_valid
        expect(page.errors[:description]).to include('is too long (maximum is 500 characters)')
      end

      it 'accepts valid description length' do
        page = build(:page, description: 'a' * 500)
        expect(page).to be_valid
      end
    end
  end

  describe 'todo limit methods' do
    describe '#can_add_todo?' do
      it 'always returns true (unlimited todos)' do
        user = create(:user)
        page = create(:page, user: user)
        create_list(:todo, 100, page: page) # Even with many todos
        expect(page.can_add_todo?).to be true
      end
    end

    describe '#remaining_todos' do
      it 'always returns infinity (unlimited todos)' do
        user = create(:user)
        page = create(:page, user: user)
        create_list(:todo, 50, page: page) # Even with many todos
        expect(page.remaining_todos).to eq('∞')
      end
    end

    describe '#at_todo_limit?' do
      it 'always returns false (unlimited todos)' do
        user = create(:user)
        page = create(:page, user: user)
        create_list(:todo, 100, page: page) # Even with many todos
        expect(page.at_todo_limit?).to be false
      end
    end
  end

  describe 'todo statistics methods' do
    describe '#total_todos_count' do
      it 'returns correct count' do
        page = create(:page)
        create_list(:todo, 5, page: page)
        expect(page.total_todos_count).to eq(5)
      end

      it 'returns 0 when no todos' do
        page = create(:page)
        expect(page.total_todos_count).to eq(0)
      end
    end

    describe '#completed_todos_count' do
      it 'returns correct count' do
        page = create(:page)
        create_list(:todo, 3, page: page, completed: true)
        create_list(:todo, 2, page: page, completed: false)
        expect(page.completed_todos_count).to eq(3)
      end

      it 'returns 0 when no completed todos' do
        page = create(:page)
        create_list(:todo, 3, page: page, completed: false)
        expect(page.completed_todos_count).to eq(0)
      end
    end

    describe '#incomplete_todos_count' do
      it 'returns correct count' do
        page = create(:page)
        create_list(:todo, 3, page: page, completed: true)
        create_list(:todo, 2, page: page, completed: false)
        expect(page.incomplete_todos_count).to eq(2)
      end

      it 'returns 0 when no incomplete todos' do
        page = create(:page)
        create_list(:todo, 3, page: page, completed: true)
        expect(page.incomplete_todos_count).to eq(0)
      end
    end
  end

  describe 'ProgressCalculatable concern' do
    describe '#completion_percentage' do
      it 'returns 0 when no todos' do
        page = create(:page)
        expect(page.completion_percentage).to eq(0)
      end

      it 'returns 100 when all todos completed' do
        page = create(:page)
        create_list(:todo, 3, page: page, completed: true)
        expect(page.completion_percentage).to eq(100)
      end

      it 'returns 50 when half completed' do
        page = create(:page)
        create_list(:todo, 2, page: page, completed: true)
        create_list(:todo, 2, page: page, completed: false)
        expect(page.completion_percentage).to eq(50)
      end

      it 'returns 33 when 1 of 3 completed' do
        page = create(:page)
        create_list(:todo, 1, page: page, completed: true)
        create_list(:todo, 2, page: page, completed: false)
        expect(page.completion_percentage).to eq(33)
      end

      it 'returns 67 when 2 of 3 completed' do
        page = create(:page)
        create_list(:todo, 2, page: page, completed: true)
        create_list(:todo, 1, page: page, completed: false)
        expect(page.completion_percentage).to eq(67)
      end
    end

    describe '#progress_text' do
      it 'returns correct format' do
        page = create(:page)
        create_list(:todo, 3, page: page, completed: true)
        create_list(:todo, 2, page: page, completed: false)
        expect(page.progress_text).to eq('3/5')
      end

      it 'returns 0/0 when no todos' do
        page = create(:page)
        expect(page.progress_text).to eq('0/0')
      end
    end

    describe '#completed?' do
      it 'returns true when all todos completed' do
        page = create(:page)
        create_list(:todo, 3, page: page, completed: true)
        expect(page.completed?).to be true
      end

      it 'returns false when some todos incomplete' do
        page = create(:page)
        create_list(:todo, 2, page: page, completed: true)
        create_list(:todo, 1, page: page, completed: false)
        expect(page.completed?).to be false
      end

      it 'returns false when no todos' do
        page = create(:page)
        expect(page.completed?).to be false
      end
    end

    describe '#empty?' do
      it 'returns true when no todos' do
        page = create(:page)
        expect(page.empty?).to be true
      end

      it 'returns false when has todos' do
        page = create(:page)
        create(:todo, page: page)
        expect(page.empty?).to be false
      end
    end

    describe '#progress_status' do
      it 'returns :empty when no todos' do
        page = create(:page)
        expect(page.progress_status).to eq(:empty)
      end

      it 'returns :completed when all todos completed' do
        page = create(:page)
        create_list(:todo, 3, page: page, completed: true)
        expect(page.progress_status).to eq(:completed)
      end

      it 'returns :in_progress when some todos incomplete' do
        page = create(:page)
        create_list(:todo, 2, page: page, completed: true)
        create_list(:todo, 1, page: page, completed: false)
        expect(page.progress_status).to eq(:in_progress)
      end
    end

    describe '#progress_color_class' do
      it 'returns gray for empty' do
        page = create(:page)
        expect(page.progress_color_class).to eq('text-gray-500')
      end

      it 'returns green for completed' do
        page = create(:page)
        create_list(:todo, 3, page: page, completed: true)
        expect(page.progress_color_class).to eq('text-green-600')
      end

      it 'returns blue for in progress' do
        page = create(:page)
        create_list(:todo, 2, page: page, completed: true)
        create_list(:todo, 1, page: page, completed: false)
        expect(page.progress_color_class).to eq('text-blue-600')
      end
    end

    describe '#progress_bar_width' do
      it 'returns correct percentage' do
        page = create(:page)
        create_list(:todo, 2, page: page, completed: true)
        create_list(:todo, 2, page: page, completed: false)
        expect(page.progress_bar_width).to eq('50%')
      end

      it 'returns 0% when no todos' do
        page = create(:page)
        expect(page.progress_bar_width).to eq('0%')
      end
    end

    describe '#at_threshold?' do
      it 'returns true when at threshold' do
        page = create(:page)
        create_list(:todo, 2, page: page, completed: true)
        create_list(:todo, 2, page: page, completed: false)
        expect(page.at_threshold?(50)).to be true
      end

      it 'returns false when below threshold' do
        page = create(:page)
        create_list(:todo, 1, page: page, completed: true)
        create_list(:todo, 3, page: page, completed: false)
        expect(page.at_threshold?(50)).to be false
      end
    end

    describe '#progress_milestone' do
      it 'returns :started for 0-24%' do
        page = create(:page)
        create_list(:todo, 1, page: page, completed: true)
        create_list(:todo, 4, page: page, completed: false)
        expect(page.progress_milestone).to eq(:started)
      end

      it 'returns :quarter for 25-49%' do
        page = create(:page)
        create_list(:todo, 1, page: page, completed: true)
        create_list(:todo, 3, page: page, completed: false)
        expect(page.progress_milestone).to eq(:quarter)
      end

      it 'returns :half for 50-74%' do
        page = create(:page)
        create_list(:todo, 2, page: page, completed: true)
        create_list(:todo, 2, page: page, completed: false)
        expect(page.progress_milestone).to eq(:half)
      end

      it 'returns :three_quarters for 75-99%' do
        page = create(:page)
        create_list(:todo, 3, page: page, completed: true)
        create_list(:todo, 1, page: page, completed: false)
        expect(page.progress_milestone).to eq(:three_quarters)
      end

      it 'returns :completed for 100%' do
        page = create(:page)
        create_list(:todo, 3, page: page, completed: true)
        expect(page.progress_milestone).to eq(:completed)
      end
    end

    describe '#progress_message' do
      it 'returns motivational message for started' do
        page = create(:page)
        create_list(:todo, 1, page: page, completed: true)
        create_list(:todo, 4, page: page, completed: false)
        expect(page.progress_message).to eq('Great start! Keep going! 🚀')
      end

      it 'returns motivational message for quarter' do
        page = create(:page)
        create_list(:todo, 1, page: page, completed: true)
        create_list(:todo, 3, page: page, completed: false)
        expect(page.progress_message).to eq("You're making progress! 📈")
      end

      it 'returns motivational message for half' do
        page = create(:page)
        create_list(:todo, 2, page: page, completed: true)
        create_list(:todo, 2, page: page, completed: false)
        expect(page.progress_message).to eq('Halfway there! 💪')
      end

      it 'returns motivational message for three quarters' do
        page = create(:page)
        create_list(:todo, 3, page: page, completed: true)
        create_list(:todo, 1, page: page, completed: false)
        expect(page.progress_message).to eq('Almost done! 🎯')
      end

      it 'returns motivational message for completed' do
        page = create(:page)
        create_list(:todo, 3, page: page, completed: true)
        expect(page.progress_message).to eq('All done! 🎉')
      end
    end
  end

  describe 'private methods' do
    describe '#total_count' do
      it 'returns correct count' do
        page = create(:page)
        create_list(:todo, 5, page: page)
        expect(page.send(:total_count)).to eq(5)
      end
    end

    describe '#completed_count' do
      it 'returns correct count' do
        page = create(:page)
        create_list(:todo, 3, page: page, completed: true)
        create_list(:todo, 2, page: page, completed: false)
        expect(page.send(:completed_count)).to eq(3)
      end
    end
  end
end
