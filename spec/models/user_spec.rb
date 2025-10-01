require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email_address) }
    it { should validate_uniqueness_of(:email_address) }
    it { should validate_presence_of(:password) }

    describe 'password length validation' do
      subject { build(:user, password: password, password_confirmation: password) }

      context 'with password shorter than 6 characters' do
        let(:password) { '12345' }
        it { should_not be_valid }
      end

      context 'with password 6 characters or longer' do
        let(:password) { '123456' }
        it { should be_valid }
      end
    end
  end

  describe 'associations' do
    it { should have_many(:pages).dependent(:destroy) }
  end

  describe 'trial management' do
    let(:user) { create(:user) }

    describe '#trial_active?' do
      context 'when trial is active' do
        let(:user) { create(:user, :with_trial) }

        it 'returns true' do
          expect(user.trial_active?).to be true
        end
      end

      context 'when trial has expired' do
        let(:user) { create(:user, :trial_expired) }

        it 'returns false' do
          expect(user.trial_active?).to be false
        end
      end

      context 'when trial has not started' do
        it 'returns false' do
          expect(user.trial_active?).to be false
        end
      end
    end

    describe '#trial_expired?' do
      context 'when trial has expired' do
        let(:user) { create(:user, :trial_expired) }

        it 'returns true' do
          expect(user.trial_expired?).to be true
        end
      end

      context 'when trial is active' do
        let(:user) { create(:user, :with_trial) }

        it 'returns false' do
          expect(user.trial_expired?).to be false
        end
      end
    end

    describe '#start_trial!' do
      it 'sets trial start and expiration dates' do
        Timecop.freeze do
          user.start_trial!

          expect(user.trial_started_at).to be_within(1.second).of(Time.current)
          expect(user.trial_expires_at).to be_within(1.second).of(Time.current + 7.days)
        end
      end

      it 'returns true on success' do
        expect(user.start_trial!).to be true
      end
    end

    describe '#trial_days_remaining' do
      context 'when trial is active' do
        let(:user) { create(:user, :with_trial) }

        it 'returns the correct number of days' do
          expect(user.trial_days_remaining).to eq(2)
        end
      end

      context 'when trial has expired' do
        let(:user) { create(:user, :trial_expired) }

        it 'returns 0' do
          expect(user.trial_days_remaining).to eq(0)
        end
      end
    end

    describe '#should_show_trial_warning?' do
      context 'when 3 days remaining' do
        let(:user) { create(:user, trial_started_at: 4.days.ago, trial_expires_at: 3.days.from_now) }

        it 'returns true' do
          # Mock the trial_days_remaining to return exactly 3
          allow(user).to receive(:trial_days_remaining).and_return(3)
          expect(user.should_show_trial_warning?).to be true
        end
      end

      context 'when 1 day remaining' do
        let(:user) { create(:user, trial_started_at: 6.days.ago, trial_expires_at: 1.day.from_now) }

        it 'returns true' do
          # Mock the trial_days_remaining to return exactly 1
          allow(user).to receive(:trial_days_remaining).and_return(1)
          expect(user.should_show_trial_warning?).to be true
        end
      end

      context 'when 5 days remaining' do
        let(:user) { create(:user, trial_started_at: 2.days.ago, trial_expires_at: 5.days.from_now) }

        it 'returns false' do
          # Mock the trial_days_remaining to return exactly 5
          allow(user).to receive(:trial_days_remaining).and_return(5)
          expect(user.should_show_trial_warning?).to be false
        end
      end
    end
  end

  describe 'download management' do
    let(:user) { create(:user) }

    describe '#generate_download_token!' do
      it 'generates a secure token' do
        token = user.generate_download_token!

        expect(token).to be_present
        expect(token.length).to be >= 32
        expect(user.download_token).to eq(token)
      end
    end

    describe '#mark_as_downloaded!' do
      it 'marks user as downloaded and clears token' do
        user.update!(download_token: 'test-token')

        user.mark_as_downloaded!

        expect(user.device_downloaded).to be true
        expect(user.download_token).to be_nil
      end
    end
  end

  describe 'access control' do
    describe '#can_create_page?' do
      context 'when user has downloaded app' do
        let(:user) { create(:user, :downloaded_app) }

        it 'returns true' do
          expect(user.can_create_page?).to be true
        end
      end

      context 'when user is on trial' do
        let(:user) { create(:user, :with_trial) }

        it 'returns true' do
          expect(user.can_create_page?).to be true
        end
      end

      context 'when trial has expired and not downloaded' do
        let(:user) { create(:user, :trial_expired) }

        it 'returns false' do
          expect(user.can_create_page?).to be false
        end
      end
    end
  end
end
