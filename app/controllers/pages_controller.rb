class PagesController < ApplicationController
  # 利用規約・プライバシーポリシーは未認証でもアクセス可能
  skip_before_action :authenticate_user!, only: [:terms, :privacy]

  def terms; end

  def privacy; end

  # 既存ユーザー向け規約同意確認ページ
  def accept_terms
    # 既に同意済みの場合はダッシュボードへリダイレクト
    if current_user.terms_privacy_accepted?
      redirect_to after_sign_in_path_for(current_user)
    end
  end

  # 規約同意の更新
  def update_terms_acceptance
    if params[:terms_accepted] == 'true' && params[:privacy_accepted] == 'true'
      current_user.update!(
        terms_accepted_at: Time.current,
        privacy_accepted_at: Time.current
      )
      flash[:notice] = '利用規約とプライバシーポリシーに同意いただきありがとうございます。'
      redirect_to after_sign_in_path_for(current_user)
    else
      flash[:alert] = '利用規約とプライバシーポリシーへの同意が必要です。'
      render :accept_terms
    end
  end
end
