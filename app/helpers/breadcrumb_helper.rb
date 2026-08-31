# パンくずリスト（現在地の階層表示）を組み立てるヘルパー。
#
# 「どこから来たか」ではなく「データ上どこに属するか」を示す。
# たとえば施術記録は必ず患者に属するため階層はレコードから導けて、
# クエリパラメータやセッションで文脈を持ち回る必要がない。
# その結果、URL を直接開いてもリロードしても複数タブでも同じ階層が出る。
module BreadcrumbHelper
  # パンくずを描画する。
  # 各段は [表示名, パス] の組か、文字列（現在地＝リンクなし）で渡す。
  #
  #   breadcrumb ['施術場所', facilities_path], @facility.name
  #   breadcrumb ['施術場所', facilities_path], [@facility.name, facility_path(@facility)], '編集'
  def breadcrumb(*items)
    render 'shared/breadcrumb', items: normalize_breadcrumb_items(items)
  end

  # 各段を [表示名, パス] の形に揃える。文字列は現在地とみなしパスを nil にする。
  def normalize_breadcrumb_items(items)
    items.map do |item|
      next [item, nil] unless item.is_a?(Array)
      next item if item.size == 2 && item.first.is_a?(String)

      # splat 忘れ（配列をまるごと1引数で渡す）を実行時の不可解なエラーにせず、その場で落とす
      raise ArgumentError, "パンくずの段は [表示名, パス] の2要素で指定してください: #{item.inspect}"
    end
  end

  # 患者を起点とする階層を描画する。
  #   patient_breadcrumb @patient                 # 患者 / 山田花子
  #   patient_breadcrumb @patient, '施術履歴'      # 患者 / 山田花子 / 施術履歴
  def patient_breadcrumb(patient, *trail)
    breadcrumb(*patient_breadcrumb_items(patient, *trail))
  end

  # 患者を起点とする階層。
  # @param patient [Patient] 起点となる患者
  # @param trail [Array] 患者より下の段（末尾が現在地）
  def patient_breadcrumb_items(patient, *trail)
    items = [['患者', patients_path]]

    if trail.empty?
      items << [patient.name, nil]
    else
      items << [patient.name, patient_path(patient)]
      items.concat(normalize_breadcrumb_items(trail))
    end

    items
  end

  # 施術記録を起点とする階層を描画する。
  def medical_record_breadcrumb(record, *trail)
    breadcrumb(*medical_record_breadcrumb_items(record, *trail))
  end

  # 施術記録を起点とする階層。記録は必ず患者に属するので、
  # 患者 → 施術履歴 → その記録、までレコードだけで組み立てられる。
  # @param record [MedicalRecord] 対象の施術記録
  # @param trail [Array] 施術記録より下の段（末尾が現在地）
  def medical_record_breadcrumb_items(record, *trail)
    patient = record.patient
    items = [
      ['患者', patients_path],
      [patient.name, patient_path(patient)],
      ['施術履歴', patient_medical_records_path(patient)],
    ]
    # visit_date は DB 側に NOT NULL 制約が無いため、移行データ等で nil のとき落とさない
    visit_date = record.visit_date ? l(record.visit_date, format: :long) : '日付未設定'

    if trail.empty?
      items << [visit_date, nil]
    else
      items << [visit_date, medical_record_path(record)]
      items.concat(normalize_breadcrumb_items(trail))
    end

    items
  end

  # 管理画面の階層を描画する（「管理」を起点に付ける）。
  def admin_breadcrumb(*items)
    breadcrumb(*admin_breadcrumb_items(*items))
  end

  # 管理画面の階層。管理トップを起点に、渡された段を後ろに連ねる。
  def admin_breadcrumb_items(*items)
    [['管理', admin_root_path], *normalize_breadcrumb_items(items)]
  end
end
