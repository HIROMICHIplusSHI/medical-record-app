class PatientConsent < ApplicationRecord
  # アソシエーション
  belongs_to :patient
  belongs_to :consent_form_template
  belongs_to :medical_record
  belongs_to :facility_doctor, optional: true
  belongs_to :user

  has_many :consent_item_responses, dependent: :destroy
  has_one_attached :signature_image

  # ネストフォーム
  accepts_nested_attributes_for :consent_item_responses,
                                allow_destroy: true

  # 暗号化（個人情報保護）
  encrypts :signature_data
  encrypts :practitioner_name
  encrypts :facility_name
  encrypts :facility_address
  encrypts :facility_phone

  # バリデーション
  validates :patient, :consent_form_template, :medical_record,
            :user, presence: true
  validates :agreed_at, presence: true
  validates :signature_data, presence: { message: '署名が必要です' }

  # 看護師確認のサーバーサイドバリデーション（Critical Issue 1対応）
  # クライアントサイドバリデーションはバイパス可能なため、サーバーサイドでも必須チェック
  validates :nurse_confirmed, acceptance: { accept: true, message: '看護師による最終確認が必要です' },
                              on: :create

  # カスタムバリデーション：必須項目のチェック確認
  validate :all_required_items_checked, on: :create
  # カスタムバリデーション：署名データの検証
  validate :validate_signature_format
  validate :validate_signature_size
  validate :validate_signature_content

  # コールバック
  before_validation :set_agreed_at, on: :create
  before_create :snapshot_facility_info
  before_create :snapshot_template_title
  before_save :invalidate_pdf_cache, if: :will_save_change_to_signature_data?

  # スコープ
  scope :recent, -> { order(agreed_at: :desc) }
  scope :for_patient, ->(patient_id) { where(patient_id: patient_id) }
  scope :for_medical_record, ->(record_id) { where(medical_record_id: record_id) }

  # Ransack検索用の許可属性
  def self.ransackable_attributes(_auth_object = nil)
    %w[agreed_at created_at id medical_record_id patient_id updated_at user_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[consent_form_template consent_item_responses facility_doctor medical_record patient user]
  end

  # PDF整合性検証メソッド
  def verify_pdf_integrity?
    pdf_path = Rails.root.join('tmp', 'pdfs', "patient_consent_#{id}.pdf")
    return false unless File.exist?(pdf_path)
    return false if pdf_hash.blank?

    current_hash = Digest::SHA256.file(pdf_path).hexdigest
    current_hash == pdf_hash
  end

  # PDFハッシュ値生成・保存メソッド
  def generate_pdf_hash!
    pdf_path = Rails.root.join('tmp', 'pdfs', "patient_consent_#{id}.pdf")
    return false unless File.exist?(pdf_path)

    self.pdf_hash = Digest::SHA256.file(pdf_path).hexdigest
    save
  end

  private

  # 署名日時を自動設定
  def set_agreed_at
    self.agreed_at ||= Time.current
  end

  # 施設情報のスナップショット保存
  def snapshot_facility_info
    facility = medical_record.facility
    self.facility_name = facility.name
    self.facility_address = facility.address
    self.facility_phone = facility.phone
    self.practitioner_name = user.company_name || user.email
  end

  # テンプレートタイトルのスナップショット保存
  def snapshot_template_title
    self.template_title = consent_form_template.title if consent_form_template.present?
  end

  # 署名データ変更時にPDFキャッシュを無効化
  def invalidate_pdf_cache
    self.pdf_hash = nil
  end

  # 必須項目がすべてチェックされているか確認
  def all_required_items_checked
    return if consent_form_template.blank?

    required_items = consent_form_template.consent_form_items.where(is_required: true)
    checked_item_ids = consent_item_responses.select(&:checked).map(&:consent_form_item_id)

    required_items.each do |item|
      errors.add(:base, "必須項目「#{item.content}」にチェックが必要です") unless checked_item_ids.include?(item.id)
    end
  end

  # 署名データのフォーマット検証
  def validate_signature_format
    return if signature_data.blank?

    return if signature_data.match?(%r{\Adata:image/png;base64,[A-Za-z0-9+/=]+\z})

    errors.add(:signature_data, '署名データの形式が不正です')
  end

  # 署名データのサイズ検証
  def validate_signature_size
    return if signature_data.blank?

    base64_data = signature_data.split(',')[1]
    return if base64_data.blank?

    estimated_size = (base64_data.length * 3) / 4

    max_size = 2.megabytes
    return unless estimated_size > max_size

    errors.add(:signature_data, "署名データが大きすぎます（最大#{max_size / 1.megabyte}MB）")
  end

  # 署名データの内容検証
  def validate_signature_content
    return if signature_data.blank?

    begin
      base64_data = signature_data.split(',')[1]
      return if base64_data.blank?

      decoded = Base64.strict_decode64(base64_data)

      # PNG署名チェック（マジックナンバー）
      png_signature = "\x89PNG\r\n\x1A\n".force_encoding('ASCII-8BIT')
      errors.add(:signature_data, '不正な画像形式です') unless decoded.force_encoding('ASCII-8BIT').start_with?(png_signature)

      # 最小サイズチェック（実質的な署名があるか）
      min_size = 200 # バイト
      errors.add(:signature_data, '署名が不完全です') if decoded.length < min_size
    rescue ArgumentError
      errors.add(:signature_data, 'Base64デコードエラー')
    end
  end
end
