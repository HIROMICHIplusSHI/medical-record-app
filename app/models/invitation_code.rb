# frozen_string_literal: true

# 招待コードモデル
# クローズドβ運用のための招待制登録システム
#
# @attr [String] code 招待コード本体（6〜12文字の英数字大文字）
# @attr [Integer] max_uses 最大使用回数（nilの場合は無制限）
# @attr [Integer] used_count 使用回数
# @attr [DateTime] expires_at 有効期限
# @attr [Integer] created_by_id 作成した管理者のID
# @attr [Integer] status ステータス（active/inactive）
# @attr [Text] memo メモ（管理者用）
class InvitationCode < ApplicationRecord
  # アソシエーション
  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_id'
  has_many :users, dependent: :nullify

  # Enum
  enum :status, { active: 0, inactive: 1 }, default: :active

  # バリデーション
  validates :code, presence: true,
                   uniqueness: { case_sensitive: false },
                   format: {
                     with: /\A[A-Z0-9]{6,12}\z/,
                     message: 'は6〜12文字の英数字（大文字）で入力してください',
                   }
  validates :max_uses, numericality: { greater_than: 0, allow_nil: true }
  validates :used_count, numericality: { greater_than_or_equal_to: 0 }
  validates :created_by, presence: true

  # スコープ
  scope :active, -> { where(status: :active) }
  scope :available, lambda {
    active.where('expires_at IS NULL OR expires_at > ?', Time.current)
  }

  # 使用可能かチェック
  # @return [Boolean]
  def available?
    active? && !expired? && !max_uses_reached?
  end

  # 有効期限切れかチェック
  # @return [Boolean]
  def expired?
    expires_at.present? && expires_at < Time.current
  end

  # 使用回数上限に達したかチェック
  # @return [Boolean]
  def max_uses_reached?
    max_uses.present? && used_count >= max_uses
  end

  # 使用回数をインクリメント
  # @return [Boolean] 更新成功/失敗
  def increment_used_count!
    increment!(:used_count)
  end

  # 残り使用回数を計算
  # @return [Float, Integer] 残り回数（無制限の場合はFloat::INFINITY）
  def remaining_uses
    return Float::INFINITY if max_uses.nil?

    [max_uses - used_count, 0].max
  end

  # ランダムな招待コードを生成（重複チェック付き）
  # @param length [Integer] コードの長さ（デフォルト: 8）
  # @return [String] 生成されたコード
  def self.generate_code(length: 8)
    loop do
      code = SecureRandom.alphanumeric(length).upcase
      break code unless exists?(code: code)
    end
  end
end
