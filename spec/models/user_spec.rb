require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:facilities).dependent(:destroy) }
    it { is_expected.to have_many(:patients).dependent(:destroy) }
    it { is_expected.to have_many(:medical_records).dependent(:destroy) }
    it { is_expected.to have_many(:cost_sheets).dependent(:destroy) }
    it { is_expected.to have_many(:invoices).dependent(:destroy) }
    it { is_expected.to have_many(:tags).dependent(:destroy) }
    it { is_expected.to have_many(:consent_form_templates).dependent(:destroy) }
    it { is_expected.to have_many(:patient_consents).dependent(:destroy) }
    it { is_expected.to have_many(:announcements).with_foreign_key(:author_id).dependent(:destroy).inverse_of(:author) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }

    describe 'company_email' do
      it { is_expected.to allow_value('company@example.com').for(:company_email) }
      it { is_expected.to allow_value('').for(:company_email) }
      it { is_expected.to allow_value(nil).for(:company_email) }
      it { is_expected.not_to allow_value('invalid-email').for(:company_email) }
    end

    describe 'company_phone' do
      it { is_expected.to validate_length_of(:company_phone).is_at_most(30) }
      it { is_expected.to allow_value('').for(:company_phone) }
      it { is_expected.to allow_value(nil).for(:company_phone) }
    end
  end

  describe 'roles' do
    let(:user) { create(:user) }
    let(:admin) { create(:user, role: :admin) }

    it 'デフォルトでuserロールが設定される' do
      admin = create(:user, :admin, create_invitation_code: false)
      create(:invitation_code, created_by: admin, code: 'ROLETEST1')

      new_user = User.create!(
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        terms_accepted_at: Time.current,
        privacy_accepted_at: Time.current,
        invitation_code_input: 'ROLETEST1'
      )
      expect(new_user.role).to eq('user')
      expect(new_user.user?).to be true
      expect(new_user.admin?).to be false
    end

    it 'adminロールを設定できる' do
      expect(admin.role).to eq('admin')
      expect(admin.admin?).to be true
      expect(admin.user?).to be false
    end

    it 'enum メソッド（admin!）でのrole変更も防止される' do
      expect { user.admin! }.to raise_error(ActiveRecord::RecordNotSaved)
      expect(user.reload.role).to eq('user')
    end

    it 'enum メソッド（user!）でのrole変更も防止される' do
      expect { admin.user! }.to raise_error(ActiveRecord::RecordNotSaved)
      expect(admin.reload.role).to eq('admin')
    end

    describe 'Mass Assignment保護' do
      it 'update経由でのrole変更が防止される' do
        user.update(role: :admin)
        expect(user.reload.role).to eq('user')
        expect(user.errors[:role]).to include('は変更できません')
      end

      it 'update!経由でのrole変更がエラーになる' do
        expect { user.update!(role: :admin) }.to raise_error(ActiveRecord::RecordNotSaved)
        expect(user.reload.role).to eq('user')
      end

      it 'allow_role_change!を使用するとrole変更が許可される' do
        user.allow_role_change!
        user.update(role: :admin)
        expect(user.reload.role).to eq('admin')
      end
    end
  end

  describe '.from_omniauth' do
    let(:auth) do
      OmniAuth::AuthHash.new({
                               provider: 'google_oauth2',
                               uid: '123456789',
                               info: {
                                 email: 'oauth@example.com',
                                 name: 'OAuth User',
                               },
                             })
    end

    it 'OAuthユーザーを作成する' do
      expect do
        User.from_omniauth(auth)
      end.to change(User, :count).by(1)

      user = User.last
      expect(user.email).to eq('oauth@example.com')
      expect(user.name).to eq('OAuth User')
      expect(user.provider).to eq('google_oauth2')
      expect(user.uid).to eq('123456789')
    end

    it '既存のOAuthユーザーは作成しない' do
      User.from_omniauth(auth)

      expect do
        User.from_omniauth(auth)
      end.not_to change(User, :count)
    end

    it 'OAuth認証時に規約同意タイムスタンプが自動設定される' do
      user = User.from_omniauth(auth)

      expect(user.terms_accepted_at).to be_present
      expect(user.privacy_accepted_at).to be_present
      expect(user.terms_privacy_accepted?).to be true
    end
  end

  describe '規約同意' do
    describe 'バリデーション' do
      it '規約同意なしでは新規作成できない' do
        user = User.new(
          email: 'test@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        )

        expect(user.valid?).to be false
        expect(user.errors[:terms_accepted_at]).to include('利用規約への同意が必要です')
        expect(user.errors[:privacy_accepted_at]).to include('プライバシーポリシーへの同意が必要です')
      end

      it '規約同意ありで新規作成できる' do
        admin = create(:user, :admin, create_invitation_code: false)
        create(:invitation_code, created_by: admin, code: 'TESTCODE')

        user = User.new(
          email: 'test@example.com',
          password: 'password123',
          password_confirmation: 'password123',
          terms_accepted_at: Time.current,
          privacy_accepted_at: Time.current,
          invitation_code_input: 'TESTCODE'
        )

        expect(user.valid?).to be true
      end

      it '既存ユーザーの更新時はバリデーションされない' do
        user = create(:user)
        user.terms_accepted_at = nil
        user.privacy_accepted_at = nil

        expect(user.valid?).to be true
      end
    end

    describe 'ヘルパーメソッド' do
      let(:user_with_acceptance) { create(:user) }
      let(:user_without_acceptance) { build(:user, :without_terms_acceptance) }

      describe '#terms_accepted?' do
        it '利用規約同意済みの場合trueを返す' do
          expect(user_with_acceptance.terms_accepted?).to be true
        end

        it '利用規約未同意の場合falseを返す' do
          expect(user_without_acceptance.terms_accepted?).to be false
        end
      end

      describe '#privacy_accepted?' do
        it 'プライバシーポリシー同意済みの場合trueを返す' do
          expect(user_with_acceptance.privacy_accepted?).to be true
        end

        it 'プライバシーポリシー未同意の場合falseを返す' do
          expect(user_without_acceptance.privacy_accepted?).to be false
        end
      end

      describe '#terms_privacy_accepted?' do
        it '両方同意済みの場合trueを返す' do
          expect(user_with_acceptance.terms_privacy_accepted?).to be true
        end

        it '利用規約のみ未同意の場合falseを返す' do
          user = build(:user, privacy_accepted_at: Time.current, terms_accepted_at: nil)
          expect(user.terms_privacy_accepted?).to be false
        end

        it 'プライバシーポリシーのみ未同意の場合falseを返す' do
          user = build(:user, terms_accepted_at: Time.current, privacy_accepted_at: nil)
          expect(user.terms_privacy_accepted?).to be false
        end

        it '両方未同意の場合falseを返す' do
          expect(user_without_acceptance.terms_privacy_accepted?).to be false
        end
      end
    end
  end
end
