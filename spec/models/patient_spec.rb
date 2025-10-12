require 'rails_helper'

RSpec.describe Patient, type: :model do
  describe 'アソシエーション' do
    it { should belong_to(:user) }
    it { should have_one(:questionnaire).dependent(:destroy) }
  end

  describe 'バリデーション' do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(100) }

    describe 'date_of_birth' do
      let(:user) { create(:user) }

      it '過去の日付は有効' do
        patient = build(:patient, user: user, date_of_birth: 1.day.ago)
        expect(patient).to be_valid
      end

      it '今日の日付は有効' do
        patient = build(:patient, user: user, date_of_birth: Date.today)
        expect(patient).to be_valid
      end

      it '未来の日付は無効' do
        patient = build(:patient, user: user, date_of_birth: 1.day.from_now)
        expect(patient).not_to be_valid
        expect(patient.errors[:date_of_birth]).to include('は今日以前の日付を入力してください')
      end
    end

    describe 'phone' do
      let(:user) { create(:user) }

      it '正しい電話番号形式は有効' do
        valid_phones = ['03-1234-5678', '0312345678', '090-1234-5678', '09012345678']
        valid_phones.each do |phone|
          patient = build(:patient, user: user, phone: phone)
          expect(patient).to be_valid
        end
      end

      it '不正な電話番号形式は無効' do
        patient = build(:patient, user: user, phone: 'invalid')
        expect(patient).not_to be_valid
        expect(patient.errors[:phone]).to include('は正しい電話番号の形式で入力してください')
      end

      it '空白は有効' do
        patient = build(:patient, user: user, phone: nil)
        expect(patient).to be_valid
      end
    end

    describe 'email' do
      let(:user) { create(:user) }

      it '正しいメールアドレス形式は有効' do
        patient = build(:patient, user: user, email: 'test@example.com')
        expect(patient).to be_valid
      end

      it '不正なメールアドレス形式は無効' do
        patient = build(:patient, user: user, email: 'invalid')
        expect(patient).not_to be_valid
        expect(patient.errors[:email]).to include('は正しいメールアドレスの形式で入力してください')
      end

      it '空白は有効' do
        patient = build(:patient, user: user, email: nil)
        expect(patient).to be_valid
      end
    end
  end

  describe 'enum' do
    it do
      should define_enum_for(:gender).with_values(
        unspecified: 0,
        male: 1,
        female: 2,
        other: 3,
      )
    end
  end

  describe 'スコープ' do
    let(:user) { create(:user) }

    describe '.recent' do
      it '作成日時の降順で返す' do
        patient1 = create(:patient, user: user, created_at: 2.days.ago)
        patient2 = create(:patient, user: user, created_at: 1.day.ago)
        patient3 = create(:patient, user: user, created_at: Time.current)

        expect(user.patients.recent).to eq([patient3, patient2, patient1])
      end
    end
  end

  describe '暗号化' do
    let(:user) { create(:user) }
    let(:patient) { create(:patient, user: user) }

    it 'nameが暗号化されている' do
      # データベースの値を直接確認
      raw_value = ActiveRecord::Base.connection.execute(
        "SELECT name FROM patients WHERE id = #{patient.id}",
      ).first['name']

      expect(raw_value).not_to eq(patient.name)
    end

    it 'emailが暗号化されている' do
      patient_with_email = create(:patient, user: user, email: 'test@example.com')
      raw_value = ActiveRecord::Base.connection.execute(
        "SELECT email FROM patients WHERE id = #{patient_with_email.id}",
      ).first['email']

      expect(raw_value).not_to eq('test@example.com')
    end

    it '暗号化されたデータを正しく復号化できる' do
      patient.reload
      expect(patient.name).to be_present
      expect(patient.name).to be_a(String)
    end
  end
end
