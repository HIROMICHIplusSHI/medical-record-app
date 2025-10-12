class Patient < ApplicationRecord
  # アソシエーション
  belongs_to :user
  has_one :questionnaire, dependent: :destroy

  # 暗号化
  encrypts :name
  encrypts :phone
  encrypts :email, deterministic: true # 検索可能な暗号化
  encrypts :address
  encrypts :emergency_contact

  # enum
  enum gender: {
    unspecified: 0,
    male: 1,
    female: 2,
    other: 3,
  }

  # バリデーション
  validates :name, presence: true, length: { maximum: 100 }
  validates :date_of_birth, comparison: { less_than_or_equal_to: -> { Date.today }, message: 'は今日以前の日付を入力してください' },
                            allow_blank: true
  validates :phone, format: { with: /\A\d{2,4}-?\d{2,4}-?\d{3,4}\z/, message: 'は正しい電話番号の形式で入力してください' },
                    allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: 'は正しいメールアドレスの形式で入力してください' },
                    allow_blank: true

  # スコープ
  scope :recent, -> { order(created_at: :desc) }
end
