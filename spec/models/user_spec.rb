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
      new_user = User.create!(
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123'
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

    it 'roleをuserからadminに変更できる' do
      user.admin!
      expect(user.reload.role).to eq('admin')
      expect(user.admin?).to be true
    end

    it 'roleをadminからuserに変更できる' do
      admin.user!
      expect(admin.reload.role).to eq('user')
      expect(admin.user?).to be true
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
  end
end
