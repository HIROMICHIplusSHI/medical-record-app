class PagesController < ApplicationController
  # 利用規約・プライバシーポリシーは未認証でもアクセス可能
  skip_before_action :authenticate_user!

  def terms; end

  def privacy; end
end
