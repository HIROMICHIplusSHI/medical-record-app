require 'rails_helper'

RSpec.describe Questionnaire, type: :model do
  describe 'アソシエーション' do
    it { should belong_to(:patient) }
  end

  describe 'バリデーション' do
    let(:patient) { create(:patient) }

    it '患者1人につき1つの問診票のみ作成可能' do
      create(:questionnaire, patient: patient)
      duplicate_questionnaire = build(:questionnaire, patient: patient)

      expect(duplicate_questionnaire).not_to be_valid
      expect(duplicate_questionnaire.errors[:patient]).to include('はすでに問診票が存在します')
    end

    it '必須フィールドが存在する場合は有効' do
      questionnaire = build(:questionnaire)
      expect(questionnaire).to be_valid
    end

    it 'full_nameが必須' do
      questionnaire = build(:questionnaire, full_name: nil)
      expect(questionnaire).not_to be_valid
      expect(questionnaire.errors[:full_name]).to be_present
    end

    it 'phoneが必須' do
      questionnaire = build(:questionnaire, phone: nil)
      expect(questionnaire).not_to be_valid
      expect(questionnaire.errors[:phone]).to be_present
    end
  end

  describe '暗号化' do
    let(:patient) { create(:patient) }
    let(:questionnaire) { create(:questionnaire, :with_medical_conditions, patient: patient) }

    it 'full_nameが暗号化されている' do
      raw_value = ActiveRecord::Base.connection.execute(
        "SELECT full_name FROM questionnaires WHERE id = #{questionnaire.id}"
      ).first['full_name']

      expect(raw_value).not_to eq('田中 花子')
    end

    it 'phoneが暗号化されている' do
      raw_value = ActiveRecord::Base.connection.execute(
        "SELECT phone FROM questionnaires WHERE id = #{questionnaire.id}"
      ).first['phone']

      expect(raw_value).not_to eq('090-1234-5678')
    end

    it 'medical_conditionsが暗号化されている' do
      raw_value = ActiveRecord::Base.connection.execute(
        "SELECT medical_conditions FROM questionnaires WHERE id = #{questionnaire.id}"
      ).first['medical_conditions']

      expect(raw_value).not_to eq('高血圧、治療中')
    end

    it 'current_medicationsが暗号化されている' do
      raw_value = ActiveRecord::Base.connection.execute(
        "SELECT current_medications FROM questionnaires WHERE id = #{questionnaire.id}"
      ).first['current_medications']

      expect(raw_value).not_to eq('アムロジピン 5mg、メトホルミン 500mg')
    end

    it 'allergiesが暗号化されている' do
      raw_value = ActiveRecord::Base.connection.execute(
        "SELECT allergies FROM questionnaires WHERE id = #{questionnaire.id}"
      ).first['allergies']

      expect(raw_value).not_to eq('花粉症、猫アレルギー')
    end

    it 'desired_treatmentsが暗号化されている' do
      raw_value = ActiveRecord::Base.connection.execute(
        "SELECT desired_treatments FROM questionnaires WHERE id = #{questionnaire.id}"
      ).first['desired_treatments']

      expect(raw_value).not_to eq('眉毛、リップアートメイク')
    end

    it '暗号化されたデータを正しく復号化できる' do
      questionnaire.reload
      expect(questionnaire.full_name).to eq('田中 花子')
      expect(questionnaire.full_name_kana).to eq('タナカ ハナコ')
      expect(questionnaire.birth_date).to eq('1985-05-15')
      expect(questionnaire.gender).to eq('female')
      expect(questionnaire.medical_conditions).to eq('高血圧、治療中')
      expect(questionnaire.current_medications).to eq('アムロジピン 5mg、メトホルミン 500mg')
      expect(questionnaire.allergies).to eq('花粉症、猫アレルギー')
      expect(questionnaire.past_surgeries).to eq('虫垂炎手術（2015年）')
      expect(questionnaire.pregnancy_info).to eq('該当なし')
      expect(questionnaire.desired_treatments).to eq('眉毛、リップアートメイク')
      expect(questionnaire.past_treatments).to eq('2020年に眉のアートメイク経験あり')
      expect(questionnaire.skin_conditions).to eq('敏感肌、乾燥しやすい')
      expect(questionnaire.other_concerns).to eq('自然な仕上がりを希望')
    end
  end
end
