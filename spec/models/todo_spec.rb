require 'rails_helper'

RSpec.describe Todo, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:page) }
  end

  describe 'associations' do
    it { should belong_to(:page) }
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:page) { create(:page, user: user) }
    let!(:todo1) { create(:todo, page: page, position: 1) }
    let!(:todo2) { create(:todo, page: page, position: 2) }
    let!(:todo3) { create(:todo, page: page, position: 3) }

    describe '.ordered' do
      it 'returns todos in position order' do
        expect(Todo.ordered).to eq([ todo1, todo2, todo3 ])
      end
    end

    describe '.completed' do
      before do
        todo1.update!(completed: true)
        todo2.update!(completed: false)
        todo3.update!(completed: true)
      end

      it 'returns only completed todos' do
        expect(Todo.completed).to contain_exactly(todo1, todo3)
      end
    end

    describe '.pending' do
      before do
        todo1.update!(completed: true)
        todo2.update!(completed: false)
        todo3.update!(completed: true)
      end

      it 'returns only pending todos' do
        expect(Todo.pending).to contain_exactly(todo2)
      end
    end
  end

  describe 'due date management' do
    let(:user) { create(:user) }
    let(:page) { create(:page, user: user) }
    let(:todo) { create(:todo, page: page) }

    describe '#overdue?' do
      context 'when due date is in the past' do
        before { todo.update!(due_date: 1.day.ago) }

        it 'returns true' do
          expect(todo.overdue?).to be true
        end
      end

      context 'when due date is today' do
        before { todo.update!(due_date: Date.current) }

        it 'returns false' do
          expect(todo.overdue?).to be false
        end
      end

      context 'when due date is in the future' do
        before { todo.update!(due_date: 1.day.from_now) }

        it 'returns false' do
          expect(todo.overdue?).to be false
        end
      end

      context 'when no due date is set' do
        it 'returns false' do
          expect(todo.overdue?).to be false
        end
      end
    end

    describe '#due_today?' do
      context 'when due date is today' do
        before { todo.update!(due_date: Date.current) }

        it 'returns true' do
          expect(todo.due_today?).to be true
        end
      end

      context 'when due date is not today' do
        before { todo.update!(due_date: 1.day.from_now) }

        it 'returns false' do
          expect(todo.due_today?).to be false
        end
      end
    end

    describe '#due_soon?' do
      context 'when due within 3 days' do
        before { todo.update!(due_date: 2.days.from_now) }

        it 'returns true' do
          expect(todo.due_soon?).to be true
        end
      end

      context 'when due in more than 3 days' do
        before { todo.update!(due_date: 5.days.from_now) }

        it 'returns false' do
          expect(todo.due_soon?).to be false
        end
      end
    end
  end

  describe 'completion status' do
    let(:user) { create(:user) }
    let(:page) { create(:page, user: user) }
    let(:todo) { create(:todo, page: page) }

    describe '#toggle_completion!' do
      context 'when todo is not completed' do
        it 'marks todo as completed' do
          todo.toggle_completion!
          expect(todo.completed).to be true
        end
      end

      context 'when todo is completed' do
        before { todo.update!(completed: true) }

        it 'marks todo as not completed' do
          todo.toggle_completion!
          expect(todo.completed).to be false
        end
      end
    end
  end

  describe 'position management' do
    let(:user) { create(:user) }
    let(:page) { create(:page, user: user) }

    describe '#move_to_position' do
      let!(:todo1) { create(:todo, page: page, position: 1) }
      let!(:todo2) { create(:todo, page: page, position: 2) }
      let!(:todo3) { create(:todo, page: page, position: 3) }

      it 'reorders todos correctly' do
        todo1.move_to_position(3)

        expect(todo1.reload.position).to eq(3)
        expect(todo2.reload.position).to eq(1)
        expect(todo3.reload.position).to eq(2)
      end
    end
  end
end
