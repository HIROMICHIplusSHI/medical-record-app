require 'rails_helper'

RSpec.describe 'patients/show.html.erb', type: :view do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:patient) { create(:patient, user: user) }

  before do
    sign_in user
    assign(:patient, patient)
  end

  context '問診票が存在する場合' do
    let!(:questionnaire) do
      create(:questionnaire,
             patient: patient,
             full_name: '<script>alert("XSS")</script>',
             phone: '<img src=x onerror="alert(1)">',
             gender: '<iframe src="javascript:alert(1)"></iframe>',
             birth_date: '<svg onload="alert(1)">',
             address: '<body onload="alert(1)">')
    end

    before { render }

    it '氏名のXSS攻撃がエスケープされる' do
      expect(rendered).to include('&lt;script&gt;')
      expect(rendered).not_to include('<script>alert("XSS")</script>')
    end

    it '電話番号のXSS攻撃がエスケープされる' do
      expect(rendered).to include('&lt;img')
      expect(rendered).not_to include('<img src=x onerror')
    end

    it '性別が不正な値の場合は「未登録」と表示される' do
      # 不正な値（XSS攻撃文字列）の場合、case文のelse節で"未登録"が表示される
      expect(rendered).to include('未登録')
      # XSS攻撃文字列は表示されない（エスケープされる）
      expect(rendered).not_to include('<iframe src=')
    end

    it '生年月日のXSS攻撃がエスケープされる（rescue節）' do
      expect(rendered).to include('&lt;svg')
      expect(rendered).not_to include('<svg onload=')
    end

    it '住所のXSS攻撃がエスケープされる' do
      expect(rendered).to include('&lt;body')
      expect(rendered).not_to include('<body onload=')
    end
  end

  context '問診票が存在しない場合' do
    before do
      patient.update(name: '<script>alert("XSS")</script>')
      render
    end

    it '患者名のXSS攻撃がエスケープされる' do
      expect(rendered).to include('&lt;script&gt;')
      expect(rendered).not_to include('<script>alert("XSS")</script>')
    end
  end
end
