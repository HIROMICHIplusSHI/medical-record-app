# frozen_string_literal: true

# 利用規約・プライバシーポリシー関連の定数
module TermsConstants
  # 利用規約・プライバシーポリシー最終更新日
  TERMS_UPDATED_AT = Date.new(2025, 10, 27).freeze
  PRIVACY_UPDATED_AT = Date.new(2025, 10, 27).freeze

  # 連絡先情報
  SERVICE_NAME = 'InkFolio'
  CONTACT_EMAIL = 'inkfolio.sup@gmail.com'
  PRIVACY_EMAIL = 'privacy@inkfolio.example.com' # TODO: 本番環境用メールアドレスに変更
  SUPPORT_HOURS = '平日10:00〜17:00（土日祝日、年末年始を除く）'

  # 事業者情報（プライバシーポリシー用）
  OPERATOR_NAME = 'InkFolio開発チーム'
  OPERATOR_ADDRESS = '（運営者住所）' # TODO: 実際の住所に変更
  PRIVACY_MANAGER = 'InkFolio 個人情報保護管理者' # TODO: 実際の担当者名に変更
end
