require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:pages).dependent(:destroy) }
  end

  describe 'validations' do
    describe 'email_address' do
      it { should validate_presence_of(:email_address) }
      it { should validate_uniqueness_of(:email_address) }

      it 'validates email format' do
        user = build(:user, email_address: 'invalid-email')
        expect(user).not_to be_valid
        expect(user.errors[:email_address]).to include('is invalid')
      end

      it 'accepts valid email formats' do
        valid_emails = [
          'user@example.com',
          'test.email+tag@domain.co.uk',
          'user123@test-domain.com'
        ]

        valid_emails.each do |email|
          user = build(:user, email_address: email)
          expect(user).to be_valid, "Expected #{email} to be valid"
        end
      end
    end

    describe 'name' do
      context 'on create' do
        it { should validate_presence_of(:name).on(:create) }
        it { should validate_length_of(:name).is_at_least(2).is_at_most(50).on(:create) }
      end

      context 'on update' do
        it 'allows blank name' do
          user = create(:user)
          user.name = ''
          expect(user).to be_valid
        end

        it 'validates length when present' do
          user = create(:user)
          user.name = 'a' # Too short
          expect(user).not_to be_valid
          expect(user.errors[:name]).to include('is too short (minimum is 2 characters)')

          user.name = 'a' * 51 # Too long
          expect(user).not_to be_valid
          expect(user.errors[:name]).to include('is too long (maximum is 50 characters)')
        end
      end
    end

    describe 'password' do
      it { should validate_length_of(:password).is_at_least(6).on(:create) }

      it 'requires password on create' do
        user = build(:user, password: nil, password_confirmation: nil)
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("can't be blank")
      end
    end
  end

  describe 'secure password functionality' do
    it 'has secure password enabled' do
      user = create(:user, password: 'testpassword123', password_confirmation: 'testpassword123')
      expect(user.authenticate('testpassword123')).to eq(user)
      expect(user.authenticate('wrongpassword')).to be_falsey
    end

    it 'encrypts password' do
      user = create(:user, password: 'testpassword123', password_confirmation: 'testpassword123')
      expect(user.password_digest).not_to eq('testpassword123')
      expect(user.password_digest).to be_present
    end
  end

  describe 'download functionality' do
    describe '#can_download?' do
      it 'returns true when download count is below limit' do
        user = create(:user, download_count: 2)
        expect(user.can_download?).to be true
      end

      it 'returns false when download count reaches limit' do
        user = create(:user, download_count: 3)
        expect(user.can_download?).to be false
      end
    end

    describe '#increment_download_count!' do
      it 'increments download count' do
        user = create(:user, download_count: 1)
        user.increment_download_count!
        expect(user.reload.download_count).to eq(2)
      end
    end

    describe '#downloads_remaining' do
      it 'calculates remaining downloads correctly' do
        user = create(:user, download_count: 1)
        expect(user.downloads_remaining).to eq(2)
      end

      it 'returns 0 when at limit' do
        user = create(:user, download_count: 3)
        expect(user.downloads_remaining).to eq(0)
      end
    end
  end

  describe 'remember token functionality' do
    describe '#remember_me!' do
      it 'generates remember token and sets expiration' do
        user = create(:user)
        user.remember_me!

        expect(user.remember_token).to be_present
        expect(user.remember_token_expires_at).to be_present
        expect(user.remember_token_expires_at).to be > 1.year.from_now - 1.minute
      end
    end

    describe '#forget_me!' do
      it 'clears remember token and expiration' do
        user = create(:user)
        user.remember_me!
        user.forget_me!

        expect(user.remember_token).to be_nil
        expect(user.remember_token_expires_at).to be_nil
      end
    end

    describe '#remember_token_valid?' do
      it 'returns true for valid token' do
        user = create(:user)
        user.remember_me!
        expect(user.remember_token_valid?).to be true
      end

      it 'returns false for expired token' do
        user = create(:user)
        user.remember_token = SecureRandom.urlsafe_base64
        user.remember_token_expires_at = 1.day.ago
        expect(user.remember_token_valid?).to be false
      end

      it 'returns false for missing token' do
        user = create(:user)
        expect(user.remember_token_valid?).to be false
      end
    end

    describe '#remember_token_expires_soon?' do
      it 'returns true when token expires within 30 days' do
        user = create(:user)
        user.remember_token = SecureRandom.urlsafe_base64
        user.remember_token_expires_at = 15.days.from_now
        expect(user.remember_token_expires_soon?).to be true
      end

      it 'returns false when token expires in more than 30 days' do
        user = create(:user)
        user.remember_token = SecureRandom.urlsafe_base64
        user.remember_token_expires_at = 60.days.from_now
        expect(user.remember_token_expires_soon?).to be false
      end
    end

    describe '#refresh_remember_token!' do
      it 'extends token expiration when valid' do
        user = create(:user)
        user.remember_me!
        original_expiry = user.remember_token_expires_at

        user.refresh_remember_token!

        expect(user.remember_token_expires_at).to be > original_expiry
      end

      it 'does nothing when token is invalid' do
        user = create(:user)
        user.remember_token = nil
        user.remember_token_expires_at = nil

        expect { user.refresh_remember_token! }.not_to change(user, :remember_token_expires_at)
      end
    end
  end

  describe '#display_name' do
    it 'returns name when present' do
      user = create(:user, name: 'John Doe')
      expect(user.display_name).to eq('John Doe')
    end

    it 'returns email when name is blank' do
      user = create(:user)
      user.update!(name: '')
      expect(user.display_name).to eq(user.email_address)
    end

    it 'returns email when name is nil' do
      user = create(:user)
      user.update!(name: nil)
      expect(user.display_name).to eq(user.email_address)
    end
  end

  describe 'TrialManageable concern' do
    describe 'trial status methods' do
      describe '#trial_active?' do
        it 'returns true when trial is active' do
          user = create(:user, :with_trial)
          expect(user.trial_active?).to be true
        end

        it 'returns false when trial is expired' do
          user = create(:user, :trial_expired)
          expect(user.trial_active?).to be false
        end

        it 'returns false when trial not started' do
          user = create(:user)
          expect(user.trial_active?).to be false
        end
      end

      describe '#trial_expired?' do
        it 'returns true when trial is expired' do
          user = create(:user, :trial_expired)
          expect(user.trial_expired?).to be true
        end

        it 'returns false when trial is active' do
          user = create(:user, :with_trial)
          expect(user.trial_expired?).to be false
        end
      end

      describe '#trial_started?' do
        it 'returns true when trial has started' do
          user = create(:user, :with_trial)
          expect(user.trial_started?).to be true
        end

        it 'returns false when trial not started' do
          user = create(:user)
          expect(user.trial_started?).to be false
        end
      end

      describe '#device_downloaded?' do
        it 'returns true when app is downloaded' do
          user = create(:user, :downloaded_app)
          expect(user.device_downloaded?).to be true
        end

        it 'returns false when app not downloaded' do
          user = create(:user)
          expect(user.device_downloaded?).to be false
        end
      end
    end

    describe 'status helpers' do
      describe '#premium?' do
        it 'returns true when app is downloaded' do
          user = create(:user, :downloaded_app)
          expect(user.premium?).to be true
        end

        it 'returns false when app not downloaded' do
          user = create(:user)
          expect(user.premium?).to be false
        end
      end

      describe '#free?' do
        it 'returns true when not premium' do
          user = create(:user)
          expect(user.free?).to be true
        end

        it 'returns false when premium' do
          user = create(:user, :downloaded_app)
          expect(user.free?).to be false
        end
      end

      describe '#on_trial?' do
        it 'returns true when trial is active and app not downloaded' do
          user = create(:user, :with_trial)
          expect(user.on_trial?).to be true
        end

        it 'returns false when trial expired' do
          user = create(:user, :trial_expired)
          expect(user.on_trial?).to be false
        end

        it 'returns false when app is downloaded' do
          user = create(:user, :downloaded_app)
          expect(user.on_trial?).to be false
        end
      end

      describe '#downloaded_app?' do
        it 'returns true when app is downloaded' do
          user = create(:user, :downloaded_app)
          expect(user.downloaded_app?).to be true
        end

        it 'returns false when app not downloaded' do
          user = create(:user)
          expect(user.downloaded_app?).to be false
        end
      end

      describe '#needs_trial_start?' do
        it 'returns true when trial not started and app not downloaded' do
          user = create(:user)
          expect(user.needs_trial_start?).to be true
        end

        it 'returns false when trial started' do
          user = create(:user, :with_trial)
          expect(user.needs_trial_start?).to be false
        end

        it 'returns false when app downloaded' do
          user = create(:user, :downloaded_app)
          expect(user.needs_trial_start?).to be false
        end
      end
    end

    describe 'access control methods' do
      describe '#can_create_page?' do
        it 'returns true when app is downloaded' do
          user = create(:user, :downloaded_app)
          expect(user.can_create_page?).to be true
        end

        it 'returns true when on trial' do
          user = create(:user, :with_trial)
          expect(user.can_create_page?).to be true
        end

        it 'returns false when trial expired and app not downloaded' do
          user = create(:user, :trial_expired)
          expect(user.can_create_page?).to be false
        end
      end

      describe '#remaining_pages' do
        it 'returns infinity when app is downloaded' do
          user = create(:user, :downloaded_app)
          expect(user.remaining_pages).to eq('∞')
        end

        it 'returns infinity when on trial' do
          user = create(:user, :with_trial)
          expect(user.remaining_pages).to eq('∞')
        end

        it 'returns 0 when trial expired and app not downloaded' do
          user = create(:user, :trial_expired)
          expect(user.remaining_pages).to eq('0')
        end
      end

      describe '#can_use_premium_themes?' do
        it 'returns true for all users' do
          user = create(:user)
          expect(user.can_use_premium_themes?).to be true
        end
      end

      describe '#can_install_pwa?' do
        it 'returns true when device_downloaded' do
          expect(create(:user, :downloaded_app).can_install_pwa?).to be true
        end

        it 'returns true when paid_at is set' do
          u = create(:user, paid_at: Time.current, device_downloaded: false)
          expect(u.can_install_pwa?).to be true
        end

        it 'returns false during trial without purchase' do
          expect(create(:user, :with_trial).can_install_pwa?).to be false
        end
      end

      describe '#can_use_app?' do
        it 'returns true during active trial' do
          expect(create(:user, :with_trial).can_use_app?).to be true
        end

        it 'returns true when purchased or legacy downloaded' do
          expect(create(:user, :downloaded_app).can_use_app?).to be true
        end

        it 'returns true when paid_at set (e.g. webhook pending)' do
          u = create(:user, :trial_expired, paid_at: Time.current, device_downloaded: false)
          expect(u.can_use_app?).to be true
        end

        it 'returns false after trial with no purchase' do
          expect(create(:user, :trial_expired).can_use_app?).to be false
        end

        it 'returns false before trial starts and without purchase' do
          expect(create(:user).can_use_app?).to be false
        end
      end
    end

    describe 'trial management methods' do
      describe '#start_trial!' do
        it 'starts trial with correct dates' do
          user = create(:user)
          Timecop.freeze do
            user.start_trial!
            expect(user.trial_started_at).to be_within(1.second).of(Time.current)
            expect(user.trial_expires_at).to be_within(1.second).of(7.days.from_now)
          end
        end

        it 'returns true on success' do
          user = create(:user)
          expect(user.start_trial!).to be true
        end
      end

      describe '#generate_download_token!' do
        it 'generates and saves download token' do
          user = create(:user)
          token = user.generate_download_token!
          expect(token).to be_present
          expect(user.reload.download_token).to eq(token)
        end
      end

      describe '#mark_as_downloaded!' do
        it 'marks user as downloaded and clears token' do
          user = create(:user, :with_download_token)
          user.mark_as_downloaded!
          expect(user.device_downloaded).to be true
          expect(user.download_token).to be_nil
        end
      end

      describe '#trial_days_remaining' do
        it 'returns correct days when trial is active' do
          user = create(:user, :with_trial)
          expect(user.trial_days_remaining).to be > 0
        end

        it 'returns 0 when trial is not active' do
          user = create(:user, :trial_expired)
          expect(user.trial_days_remaining).to eq(0)
        end
      end

      describe '#should_show_trial_warning?' do
        it 'returns true when 3 days remaining' do
          user = create(:user)
          user.trial_started_at = 4.days.ago
          user.trial_expires_at = 3.days.from_now + 1.day # Add 1 day to get exactly 3 days remaining
          user.save!
          expect(user.should_show_trial_warning?).to be true
        end

        it 'returns true when 1 day remaining' do
          user = create(:user)
          user.trial_started_at = 6.days.ago
          user.trial_expires_at = 1.day.from_now + 1.day # Add 1 day to get exactly 1 day remaining
          user.save!
          expect(user.should_show_trial_warning?).to be true
        end

        it 'returns false when more than 3 days remaining' do
          user = create(:user)
          user.trial_started_at = 2.days.ago
          user.trial_expires_at = 5.days.from_now
          user.save!
          expect(user.should_show_trial_warning?).to be false
        end

        it 'returns false when trial not active' do
          user = create(:user, :trial_expired)
          expect(user.should_show_trial_warning?).to be false
        end
      end
    end
  end
end
