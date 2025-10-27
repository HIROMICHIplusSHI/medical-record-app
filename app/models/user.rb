class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  # Phase 2では通常ログインのみ使用（OAuthは将来実装予定）
  # :omniauthable, omniauth_providers: [:google_oauth2]

  # Enums
  enum :role, {
    user: 0, # 一般ユーザー
    admin: 1, # 管理者
  }, default: :user

  # Mass Assignment対策: roleの変更を保護
  attr_accessor :skip_role_protection

  # 規約同意用の仮想属性（フォームからの送信値を受け取るため）
  attr_accessor :terms_accepted, :privacy_accepted

  before_update :prevent_role_change, unless: :skip_role_protection

  # Associations
  has_many :facilities, dependent: :destroy
  has_many :patients, dependent: :destroy
  has_many :medical_records, dependent: :destroy
  has_many :cost_sheets, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :consent_form_templates, dependent: :destroy
  has_many :patient_consents, dependent: :destroy
  has_many :announcements, foreign_key: :author_id, dependent: :destroy, inverse_of: :author
  has_many :inquiries, dependent: :destroy
  has_many :inquiry_messages, dependent: :destroy

  # Validations
  validates :company_email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :company_phone, length: { maximum: 30 }, allow_blank: true
  validates :terms_accepted_at, presence: { message: '利用規約への同意が必要です' }, on: :create
  validates :privacy_accepted_at, presence: { message: 'プライバシーポリシーへの同意が必要です' }, on: :create

  # OmniAuth
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      # OAuth認証時は利用規約・プライバシーポリシーに自動同意とみなす
      user.terms_accepted_at = Time.current
      user.privacy_accepted_at = Time.current
    end
  end

  # 管理者によるロール変更を許可するメソッド
  def allow_role_change!
    self.skip_role_protection = true
  end

  # 規約同意確認メソッド
  def terms_accepted?
    terms_accepted_at.present?
  end

  def privacy_accepted?
    privacy_accepted_at.present?
  end

  def terms_privacy_accepted?
    terms_accepted? && privacy_accepted?
  end

  private

  # ロール変更を防止（Mass Assignment対策）
  # 注意: enum メソッド（admin!、user!）も含めて全てのrole変更を防止
  # 管理者による明示的な権限変更のみ許可（allow_role_change!呼び出し後）
  def prevent_role_change
    return unless role_changed? && persisted?

    errors.add(:role, 'は変更できません')
    throw(:abort)
  end
end
