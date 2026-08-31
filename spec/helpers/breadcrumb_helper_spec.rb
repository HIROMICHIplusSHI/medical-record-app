require 'rails_helper'

RSpec.describe BreadcrumbHelper, type: :helper do
  let(:user) { create(:user) }
  let(:patient) { create(:patient, user: user, name: '山田花子') }
  let(:facility) { create(:facility, user: user) }

  describe '#normalize_breadcrumb_items' do
    it '[表示名, パス] の組はそのまま扱う' do
      expect(helper.normalize_breadcrumb_items([['患者', '/patients']]))
        .to eq([['患者', '/patients']])
    end

    it '文字列だけの要素は現在地（リンクなし）として扱う' do
      expect(helper.normalize_breadcrumb_items(['編集']))
        .to eq([['編集', nil]])
    end

    it '組と文字列が混在しても正規化する' do
      expect(helper.normalize_breadcrumb_items([['患者', '/patients'], '山田花子']))
        .to eq([['患者', '/patients'], ['山田花子', nil]])
    end
  end

  describe '#normalize_breadcrumb_items の誤用検知' do
    # splat 忘れ（breadcrumb(items) と書く）は url_for が配列を polymorphic route と
    # 解釈して不可解に落ちるため、ヘルパー側で文脈付きに落とす
    it '2要素でない配列を渡すと ArgumentError になる' do
      expect { helper.normalize_breadcrumb_items([[['患者', '/patients'], ['編集', nil]]]) }
        .to raise_error(ArgumentError, /2要素で指定してください/)
    end

    it '3要素の配列も拒否する（黙って切り捨てない）' do
      expect { helper.normalize_breadcrumb_items([%w[a b c]]) }
        .to raise_error(ArgumentError)
    end
  end

  describe '#patient_breadcrumb_items' do
    it '現在地を指定しない場合は患者自身が現在地になる' do
      expect(helper.patient_breadcrumb_items(patient))
        .to eq([['患者', patients_path], ['山田花子', nil]])
    end

    it '現在地を指定すると患者がリンクになる' do
      expect(helper.patient_breadcrumb_items(patient, '施術履歴'))
        .to eq([
                 ['患者', patients_path],
                 ['山田花子', patient_path(patient)],
                 ['施術履歴', nil],
               ])
    end
  end

  describe '#medical_record_breadcrumb_items' do
    let(:record) do
      create(:medical_record, user: user, patient: patient, facility: facility,
                              visit_date: Date.new(2026, 3, 1))
    end

    # 杭: 施術記録の階層は必ず「その記録が属する患者」から導かれる
    #     （クエリパラメータやセッションで持ち回った文脈に依存しない）
    it 'レコードが属する患者から階層を組み立てる' do
      expect(helper.medical_record_breadcrumb_items(record))
        .to eq([
                 ['患者', patients_path],
                 ['山田花子', patient_path(patient)],
                 ['施術履歴', patient_medical_records_path(patient)],
                 ['2026年03月01日', nil],
               ])
    end

    # visit_date は DB 側に NOT NULL 制約が無い（移行データ等で nil がありうる）
    it 'visit_date が nil でも例外にならない' do
      record.update_column(:visit_date, nil)

      expect { helper.medical_record_breadcrumb_items(record.reload) }.not_to raise_error
      expect(helper.medical_record_breadcrumb_items(record.reload).last).to eq(['日付未設定', nil])
    end

    it '現在地を指定すると施術記録自体がリンクになる' do
      items = helper.medical_record_breadcrumb_items(record, '編集')

      expect(items.last).to eq(['編集', nil])
      expect(items[-2]).to eq(['2026年03月01日', medical_record_path(record)])
    end
  end

  describe '#admin_breadcrumb_items' do
    it '管理トップを起点にする' do
      expect(helper.admin_breadcrumb_items(['ユーザー', '/admin/users'], '詳細'))
        .to eq([
                 ['管理', admin_root_path],
                 ['ユーザー', '/admin/users'],
                 ['詳細', nil],
               ])
    end
  end
end
