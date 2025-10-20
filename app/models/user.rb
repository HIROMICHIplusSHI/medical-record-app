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

  # Associations
  has_many :facilities, dependent: :destroy
  has_many :patients, dependent: :destroy
  has_many :medical_records, dependent: :destroy
  has_many :cost_sheets, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :consent_form_templates, dependent: :destroy
  has_many :patient_consents, dependent: :destroy

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
end
