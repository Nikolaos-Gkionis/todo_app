require 'rails_helper'

RSpec.describe Todo, type: :model do
  describe 'associations' do
    it { should belong_to(:page) }
  end

  describe 'validations' do
    describe 'title' do
      it { should validate_presence_of(:title) }
      it { should validate_length_of(:title).is_at_least(1).is_at_most(200) }
      
      it 'rejects empty title' do
        todo = build(:todo, title: '')
        expect(todo).not_to be_valid
        expect(todo.errors[:title]).to include("can't be blank")
      end

      it 'rejects title that is too long' do
        todo = build(:todo, title: 'a' * 201)
        expect(todo).not_to be_valid
        expect(todo.errors[:title]).to include('is too long (maximum is 200 characters)')
      end
    end

    describe 'page' do
      it { should validate_presence_of(:page) }
    end

    describe 'position' do
      it { should validate_numericality_of(:position).is_greater_than(0) }
    end
  end

  describe 'scopes' do
    let(:page) { create(:page) }
    let!(:todo1) { create(:todo, page: page, position: 1, completed: false) }
    let!(:todo2) { create(:todo, page: page, position: 2, completed: true) }
    let!(:todo3) { create(:todo, page: page, position: 3, completed: false) }

    describe '.ordered' do
      it 'returns todos in position order' do
        expect(Todo.ordered).to eq([todo1, todo2, todo3])
      end
    end

    describe '.completed' do
      it 'returns only completed todos' do
        expect(Todo.completed).to eq([todo2])
      end
    end

    describe '.pending' do
      it 'returns only pending todos' do
        expect(Todo.pending).to eq([todo1, todo3])
      end
    end
  end

  describe 'class methods' do
    describe '.reorder_positions!' do
      let(:page) { create(:page) }
      let!(:todo1) { create(:todo, page: page, position: 1) }
      let!(:todo2) { create(:todo, page: page, position: 2) }
      let!(:todo3) { create(:todo, page: page, position: 3) }

      it 'reorders todos according to new order' do
        new_order = [todo3.id, todo1.id, todo2.id]
        Todo.reorder_positions!(page, new_order)
        
        expect(todo3.reload.position).to eq(1)
        expect(todo1.reload.position).to eq(2)
        expect(todo2.reload.position).to eq(3)
      end

      it 'handles empty order' do
        expect { Todo.reorder_positions!(page, []) }.not_to raise_error
      end
    end
  end

  describe 'PositionManageable concern' do
    let(:page) { create(:page) }

    describe 'position validation and setting' do
      it 'sets position automatically on create' do
        todo = create(:todo, page: page)
        expect(todo.position).to eq(1)
      end

      it 'sets next position for subsequent todos' do
        todo1 = create(:todo, page: page, position: 1)
        # Create todo2 with explicit position to test the logic
        todo2 = build(:todo, page: page)
        todo2.position = nil # Clear position to trigger set_position
        todo2.save!
        expect(todo2.position).to eq(2)
      end

      it 'validates position is greater than 0' do
        todo = build(:todo, page: page, position: 0)
        expect(todo).not_to be_valid
        expect(todo.errors[:position]).to include('must be greater than 0')
      end
    end

    describe 'position movement methods' do
      let!(:todo1) { create(:todo, page: page, position: 1) }
      let!(:todo2) { create(:todo, page: page, position: 2) }
      let!(:todo3) { create(:todo, page: page, position: 3) }

      describe '#move_to_position!' do
        it 'moves todo to new position' do
          todo2.move_to_position!(1)
          expect(todo2.reload.position).to eq(1)
          expect(todo1.reload.position).to eq(2)
          expect(todo3.reload.position).to eq(3)
        end

        it 'does nothing when moving to same position' do
          expect { todo2.move_to_position!(2) }.not_to change(todo2, :position)
        end
      end

      describe '#move_to_top!' do
        it 'moves todo to position 1' do
          todo3.move_to_top!
          expect(todo3.reload.position).to eq(1)
          expect(todo1.reload.position).to eq(2)
          expect(todo2.reload.position).to eq(3)
        end
      end

      describe '#move_to_bottom!' do
        it 'moves todo to last position' do
          todo1.move_to_bottom!
          expect(todo1.reload.position).to eq(3)
          expect(todo2.reload.position).to eq(1)
          expect(todo3.reload.position).to eq(2)
        end
      end

      describe '#move_up!' do
        it 'moves todo up one position' do
          todo2.move_up!
          expect(todo2.reload.position).to eq(1)
          expect(todo1.reload.position).to eq(2)
        end

        it 'does nothing when already at top' do
          expect { todo1.move_up! }.not_to change(todo1, :position)
        end
      end

      describe '#move_down!' do
        it 'moves todo down one position' do
          todo1.move_down!
          expect(todo1.reload.position).to eq(2)
          expect(todo2.reload.position).to eq(1)
        end

        it 'does nothing when already at bottom' do
          expect { todo3.move_down! }.not_to change(todo3, :position)
        end
      end

      describe '#at_top?' do
        it 'returns true when at position 1' do
          expect(todo1.at_top?).to be true
        end

        it 'returns false when not at position 1' do
          expect(todo2.at_top?).to be false
        end
      end

      describe '#at_bottom?' do
        it 'returns true when at last position' do
          expect(todo3.at_bottom?).to be true
        end

        it 'returns false when not at last position' do
          expect(todo1.at_bottom?).to be false
        end
      end

      describe '#above_item' do
        it 'returns item above' do
          expect(todo2.above_item).to eq(todo1)
        end

        it 'returns nil when at top' do
          expect(todo1.above_item).to be_nil
        end
      end

      describe '#below_item' do
        it 'returns item below' do
          expect(todo2.below_item).to eq(todo3)
        end

        it 'returns nil when at bottom' do
          expect(todo3.below_item).to be_nil
        end
      end

      describe '#swap_with!' do
        it 'swaps positions with another item' do
          todo1.swap_with!(todo3)
          expect(todo1.reload.position).to eq(3)
          expect(todo3.reload.position).to eq(1)
        end

        it 'does nothing when swapping with self' do
          expect { todo1.swap_with!(todo1) }.not_to change(todo1, :position)
        end

        it 'does nothing when swapping with nil' do
          expect { todo1.swap_with!(nil) }.not_to change(todo1, :position)
        end
      end
    end
  end

  describe 'private methods' do
    let(:page) { create(:page) }
    let(:todo) { create(:todo, page: page) }

    describe '#association_name' do
      it 'returns :todos' do
        expect(todo.send(:association_name)).to eq(:todos)
      end
    end
  end
end