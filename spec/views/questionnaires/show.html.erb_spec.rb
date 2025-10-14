require 'rails_helper'

RSpec.describe 'questionnaires/show.html.erb', type: :view do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user) }
  let(:patient) { create(:patient, user: user) }
  let(:questionnaire) do
    create(:questionnaire,
           patient: patient,
           full_name: '<script>alert("XSS")</script>',
           phone: '<img src=x onerror="alert(1)">',
           email: '<body onload="alert(1)">',
           address: '<iframe src="javascript:alert(1)"></iframe>',
           gender: '<svg onload="alert(1)">',
           other_concerns: '<marquee>XSS</marquee>')
  end

  before do
    sign_in user
    assign(:patient, patient)
    assign(:questionnaire, questionnaire)
    render
  end

  describe '基本情報セクション' do
    it '氏名のXSS攻撃がエスケープされる' do
      expect(rendered).to include('&lt;script&gt;')
      expect(rendered).not_to include('<script>alert("XSS")</script>')
    end

    it '電話番号のXSS攻撃がエスケープされる' do
      expect(rendered).to include('&lt;img')
      expect(rendered).not_to include('<img src=x onerror')
    end

    it 'メールアドレスのXSS攻撃がエスケープされる' do
      expect(rendered).to include('&lt;body')
      expect(rendered).not_to include('<body onload=')
    end

    it '住所のXSS攻撃がエスケープされる' do
      expect(rendered).to include('&lt;iframe')
      expect(rendered).not_to include('<iframe src=')
    end

    it '性別のXSS攻撃がエスケープされる（else節）' do
      expect(rendered).to include('&lt;svg')
      expect(rendered).not_to include('<svg onload=')
    end
  end

  describe '施術情報セクション' do
    it 'その他の気になることのXSS攻撃がエスケープされる' do
      expect(rendered).to include('&lt;marquee&gt;')
      expect(rendered).not_to include('<marquee>XSS</marquee>')
    end
  end
end
