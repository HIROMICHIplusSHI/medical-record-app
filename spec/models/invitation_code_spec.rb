# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InvitationCode, type: :model do
  let(:admin) { create(:user, :admin) }

  describe 'アソシエーション' do
    it { is_expected.to belong_to(:created_by).class_name('User').with_foreign_key('created_by_id') }

    # Phase 2で実装予定（Userモデルにinvitation_code_idカラム追加後）
    xit { is_expected.to have_many(:users).dependent(:nullify) }
  end

  describe 'バリデーション' do
    subject { build(:invitation_code, created_by: admin) }

    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_uniqueness_of(:code).case_insensitive }
    it { is_expected.to allow_value('ABC123').for(:code) }
    it { is_expected.to allow_value('ABCDEFGH12').for(:code) }
    it { is_expected.not_to allow_value('abc123').for(:code) }
    it { is_expected.not_to allow_value('AB').for(:code) } # 短すぎる
    it { is_expected.not_to allow_value('ABCDEFGHIJKLM').for(:code) } # 長すぎる
    it { is_expected.not_to allow_value('ABC-123').for(:code) } # ハイフン不可
    it { is_expected.not_to allow_value('ABC 123').for(:code) } # スペース不可

    it { is_expected.to validate_numericality_of(:max_uses).is_greater_than(0).allow_nil }
    it { is_expected.to validate_numericality_of(:used_count).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_presence_of(:created_by) }
  end

  describe 'enum' do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, inactive: 1).with_default(:active) }
  end

  describe 'スコープ' do
    describe '.active' do
      it 'アクティブな招待コードのみを返す' do
        active_code = create(:invitation_code, created_by: admin, status: :active)
        create(:invitation_code, :inactive, created_by: admin)

        expect(described_class.active).to include(active_code)
        expect(described_class.active.count).to eq(1)
      end
    end

    describe '.available' do
      it 'アクティブかつ期限切れでないコードを返す' do
        available_code = create(:invitation_code, created_by: admin, status: :active, expires_at: 1.day.from_now)
        create(:invitation_code, :expired, created_by: admin)
        create(:invitation_code, :inactive, created_by: admin)

        expect(described_class.available).to include(available_code)
        expect(described_class.available.count).to eq(1)
      end

      it '有効期限がないコードも含む' do
        no_expiration_code = create(:invitation_code, created_by: admin, status: :active, expires_at: nil)

        expect(described_class.available).to include(no_expiration_code)
      end
    end
  end

  describe '#available?' do
    context '全ての条件を満たす場合' do
      it 'trueを返す' do
        code = create(:invitation_code, :fully_available, created_by: admin)

        expect(code.available?).to be true
      end
    end

    context 'ステータスがinactiveの場合' do
      it 'falseを返す' do
        code = create(:invitation_code, :inactive, created_by: admin)

        expect(code.available?).to be false
      end
    end

    context '期限切れの場合' do
      it 'falseを返す' do
        code = create(:invitation_code, :expired, created_by: admin)

        expect(code.available?).to be false
      end
    end

    context '使用回数上限に達している場合' do
      it 'falseを返す' do
        code = create(:invitation_code, :max_uses_reached, created_by: admin)

        expect(code.available?).to be false
      end
    end
  end

  describe '#expired?' do
    context 'expires_atがnilの場合' do
      it 'falseを返す' do
        code = create(:invitation_code, created_by: admin, expires_at: nil)

        expect(code.expired?).to be false
      end
    end

    context 'expires_atが未来の場合' do
      it 'falseを返す' do
        code = create(:invitation_code, created_by: admin, expires_at: 1.day.from_now)

        expect(code.expired?).to be false
      end
    end

    context 'expires_atが過去の場合' do
      it 'trueを返す' do
        code = create(:invitation_code, :expired, created_by: admin)

        expect(code.expired?).to be true
      end
    end
  end

  describe '#max_uses_reached?' do
    context 'max_usesがnilの場合' do
      it 'falseを返す（無制限）' do
        code = create(:invitation_code, created_by: admin, max_uses: nil, used_count: 100)

        expect(code.max_uses_reached?).to be false
      end
    end

    context 'used_count < max_usesの場合' do
      it 'falseを返す' do
        code = create(:invitation_code, created_by: admin, max_uses: 5, used_count: 3)

        expect(code.max_uses_reached?).to be false
      end
    end

    context 'used_count == max_usesの場合' do
      it 'trueを返す' do
        code = create(:invitation_code, :max_uses_reached, created_by: admin)

        expect(code.max_uses_reached?).to be true
      end
    end

    context 'used_count > max_usesの場合' do
      it 'trueを返す' do
        code = create(:invitation_code, created_by: admin, max_uses: 3, used_count: 5)

        expect(code.max_uses_reached?).to be true
      end
    end
  end

  describe '#increment_used_count!' do
    it 'used_countを1増やす' do
      code = create(:invitation_code, created_by: admin, used_count: 0)

      expect { code.increment_used_count! }.to change { code.reload.used_count }.from(0).to(1)
    end

    it 'データベースに永続化される' do
      code = create(:invitation_code, created_by: admin, used_count: 2)
      code.increment_used_count!

      expect(described_class.find(code.id).used_count).to eq(3)
    end
  end

  describe '#remaining_uses' do
    context 'max_usesがnilの場合' do
      it 'Float::INFINITYを返す（無制限）' do
        code = create(:invitation_code, created_by: admin, max_uses: nil)

        expect(code.remaining_uses).to eq(Float::INFINITY)
      end
    end

    context 'max_usesが設定されている場合' do
      it '正しい残り使用回数を返す' do
        code = create(:invitation_code, created_by: admin, max_uses: 10, used_count: 3)

        expect(code.remaining_uses).to eq(7)
      end
    end

    context 'used_count >= max_usesの場合' do
      it '0を返す' do
        code = create(:invitation_code, :max_uses_reached, created_by: admin)

        expect(code.remaining_uses).to eq(0)
      end
    end
  end

  describe '.generate_code' do
    it 'デフォルトで8文字のコードを生成する' do
      code = described_class.generate_code

      expect(code).to match(/\A[A-Z0-9]{8}\z/)
    end

    it '指定した長さのコードを生成する' do
      code = described_class.generate_code(length: 12)

      expect(code).to match(/\A[A-Z0-9]{12}\z/)
    end

    it '既存コードと重複しないコードを生成する' do
      create(:invitation_code, created_by: admin, code: 'EXISTING1')

      # SecureRandomのスタブを使って、最初に既存コードを返すようにする
      allow(SecureRandom).to receive(:alphanumeric).and_return('existing1', 'NEWCODE1')

      code = described_class.generate_code

      expect(code).not_to eq('EXISTING1')
      expect(code).to eq('NEWCODE1')
    end

    it '重複しないコードを生成する' do
      codes = 10.times.map { described_class.generate_code }

      expect(codes.uniq.size).to eq(10)
    end
  end
end
