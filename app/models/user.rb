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

  # Mass Assignment対策: roleの変更を保護（enum メソッド経由は許可）
  before_update :prevent_role_change, unless: -> { @allow_role_change || role_changed_by_enum? }

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

  # Validations
  validates :company_email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :company_phone, length: { maximum: 30 }, allow_blank: true

  # OmniAuth
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
    end
  end

  # 管理者によるロール変更を許可するメソッド
  def allow_role_change!
    @allow_role_change = true
  end

  private

  # ロール変更を防止（Mass Assignment対策）
  def prevent_role_change
    return unless role_changed? && persisted?

    errors.add(:role, 'は変更できません')
    throw(:abort)
  end

  # enum メソッド（admin!、user!）経由での変更かを判定
  def role_changed_by_enum?
    # caller_locations を使用して呼び出し元を確認
    # enum メソッドは ActiveRecord::Enum のメソッドを経由する
    caller_locations.any? { |loc| loc.to_s.include?('active_record/enum') }
  end
end
