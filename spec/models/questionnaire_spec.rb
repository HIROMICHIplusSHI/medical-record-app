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
      expect(duplicate_questionnaire.errors[:patient]).to include('はすでに存在します')
    end
  end

  describe '暗号化' do
    let(:patient) { create(:patient) }
    let(:questionnaire) do
      create(:questionnaire,
             patient: patient,
             medical_history: '高血圧の既往歴あり',
             current_medications: 'アムロジピン 5mg',
             allergies: '花粉症',
             past_surgeries: '虫垂炎手術（2015年）',
             family_history: '父親が糖尿病',
             lifestyle_notes: '喫煙なし、飲酒は月に1-2回',
             concerns: '最近疲れやすい')
    end

    it 'medical_historyが暗号化されている' do
      raw_value = ActiveRecord::Base.connection.execute(
        "SELECT medical_history FROM questionnaires WHERE id = #{questionnaire.id}",
      ).first['medical_history']

      expect(raw_value).not_to eq('高血圧の既往歴あり')
    end

    it 'current_medicationsが暗号化されている' do
      raw_value = ActiveRecord::Base.connection.execute(
        "SELECT current_medications FROM questionnaires WHERE id = #{questionnaire.id}",
      ).first['current_medications']

      expect(raw_value).not_to eq('アムロジピン 5mg')
    end

    it 'allergiesが暗号化されている' do
      raw_value = ActiveRecord::Base.connection.execute(
        "SELECT allergies FROM questionnaires WHERE id = #{questionnaire.id}",
      ).first['allergies']

      expect(raw_value).not_to eq('花粉症')
    end

    it '暗号化されたデータを正しく復号化できる' do
      questionnaire.reload
      expect(questionnaire.medical_history).to eq('高血圧の既往歴あり')
      expect(questionnaire.current_medications).to eq('アムロジピン 5mg')
      expect(questionnaire.allergies).to eq('花粉症')
      expect(questionnaire.past_surgeries).to eq('虫垂炎手術（2015年）')
      expect(questionnaire.family_history).to eq('父親が糖尿病')
      expect(questionnaire.lifestyle_notes).to eq('喫煙なし、飲酒は月に1-2回')
      expect(questionnaire.concerns).to eq('最近疲れやすい')
    end
  end
end
