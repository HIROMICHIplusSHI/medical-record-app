require 'rails_helper'

RSpec.describe 'Mypages', type: :request do
  describe 'GET /edit' do
    it 'returns http success' do
      get '/mypage/edit'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /update' do
    it 'returns http success' do
      get '/mypage/update'
      expect(response).to have_http_status(:success)
    end
  end
end
