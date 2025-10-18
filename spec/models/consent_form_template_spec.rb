require 'rails_helper'

RSpec.describe ConsentFormTemplate, type: :model do
  describe 'アソシエーション' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:consent_form_items).dependent(:destroy) }
    it { is_expected.to have_many(:patient_consents).dependent(:restrict_with_error) }
  end

  describe 'バリデーション' do
    subject { build(:consent_form_template) }

    it { is_expected.to validate_presence_of(:title) }

    context 'タイトルのユニーク性' do
      it '同じユーザーでタイトルが重複する場合、エラーになる' do
        user = create(:user)
        create(:consent_form_template, user: user, title: 'アートメイク施術同意書')
        duplicate_template = build(:consent_form_template, user: user, title: 'アートメイク施術同意書')

        expect(duplicate_template).not_to be_valid
        expect(duplicate_template.errors[:title]).to include('はすでに存在します')
      end

      it '異なるユーザーであれば同じタイトルでも許可される' do
        user1 = create(:user)
        user2 = create(:user)
        create(:consent_form_template, user: user1, title: 'アートメイク施術同意書')
        duplicate_template = build(:consent_form_template, user: user2, title: 'アートメイク施術同意書')

        expect(duplicate_template).to be_valid
      end
    end
  end

  describe 'スコープ' do
    describe '.active' do
      it '使用中のテンプレートのみを返す' do
        active_template = create(:consent_form_template, is_active: true)
        inactive_template = create(:consent_form_template, :inactive)

        expect(ConsentFormTemplate.active).to include(active_template)
        expect(ConsentFormTemplate.active).not_to include(inactive_template)
      end
    end

    describe '.recent' do
      it '作成日時の降順で返す' do
        old_template = create(:consent_form_template, created_at: 2.days.ago)
        new_template = create(:consent_form_template, created_at: 1.day.ago)

        expect(ConsentFormTemplate.recent).to eq([new_template, old_template])
      end
    end
  end

  describe 'ネストフォーム' do
    it 'チェック項目を含めて作成できる' do
      template = build(:consent_form_template)
      template.consent_form_items.build(content: '施術リスクを理解しました', position: 1)

      expect(template.save).to be true
      expect(template.consent_form_items.count).to eq(1)
    end
  end
end
