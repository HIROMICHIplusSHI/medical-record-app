module QuestionnairesHelper
  # JSON配列データを人間が読みやすい形式に変換
  # XSS対策: ユーザー入力をHTMLエスケープ
  def format_json_field(field_value)
    return '' if field_value.blank?

    # 既に配列の場合
    if field_value.is_a?(Array)
      return field_value.map { |v| ERB::Util.html_escape(translate_value(v)) }.join("\n").html_safe
    end

    # JSON文字列の場合
    begin
      parsed = JSON.parse(field_value)
      if parsed.is_a?(Array)
        parsed.map { |v| ERB::Util.html_escape(translate_value(v)) }.join("\n").html_safe
      elsif parsed.is_a?(String)
        ERB::Util.html_escape(translate_value(parsed))
      else
        ERB::Util.html_escape(field_value.to_s)
      end
    rescue JSON::ParserError
      # JSONパースに失敗した場合もエスケープ
      ERB::Util.html_escape(field_value.to_s)
    end
  end

  private

  # 英語の値を日本語に変換
  def translate_value(value)
    translations = {
      # 既往歴
      'hypertension' => '高血圧',
      'diabetes' => '糖尿病',
      'dyslipidemia' => '脂質異常症（高脂血症）',
      'liver_disease' => '肝機能障害',
      'kidney_disease' => '腎機能障害',
      'heart_disease' => '心疾患（不整脈、心筋梗塞など）',
      'cerebrovascular_disease' => '脳血管疾患（脳梗塞、脳出血など）',
      'thyroid_disease' => '甲状腺疾患',
      'respiratory_disease' => '喘息・呼吸器疾患',
      'epilepsy' => 'てんかん',
      'blood_disease' => '血液の病気（貧血、白血病など）',
      'cancer' => 'がん（現在治療中または過去の既往）',
      'autoimmune_disease' => '自己免疫疾患（関節リウマチ、膠原病など）',

      # アレルギー
      'drug_allergy' => '薬物アレルギー',
      'metal_allergy' => '金属アレルギー',
      'latex_allergy' => 'ラテックスアレルギー',
      'food_allergy' => '食物アレルギー',
      'hay_fever' => '花粉症',
      'atopic_dermatitis' => 'アトピー性皮膚炎',

      # 服薬
      'blood_pressure' => '血圧の薬',
      'diabetes_medication' => '糖尿病の薬（インスリン含む）',
      'anticoagulant' => '血液をサラサラにする薬（抗凝固薬・抗血小板薬）',
      'steroid' => 'ステロイド',
      'immunosuppressant' => '免疫抑制剤',
      'hormone' => 'ホルモン剤',
      'psychiatric_medication' => '精神科・心療内科の薬',
      'painkiller' => '痛み止め・鎮痛剤（常用）',
      'supplement' => 'サプリメント',

      # 妊娠・授乳
      'pregnant' => '現在妊娠中である',
      'breastfeeding' => '現在授乳中である',
      'possible_pregnancy' => '妊娠の可能性がある',

      # 希望施術
      'eyebrow' => '眉毛アートメイク',
      'eyeliner_upper' => 'アイラインアートメイク（上）',
      'eyeliner_lower' => 'アイラインアートメイク（下）',
      'lip' => 'リップアートメイク',
      'hairline' => 'ヘアラインアートメイク',
      'mole' => 'ホクロ',

      # 過去施術部位
      'eyeliner' => 'アイライン',
      'other' => 'その他',

      # 肌の状態
      'keloid' => 'ケロイド体質',
      'sensitive_skin' => '肌が弱い・敏感肌',
      'current_wound' => '現在、顔に傷や湿疹がある',
      'herpes_prone' => 'ヘルペスができやすい',
      'sunburned' => '日焼けしている',
      'none' => '該当なし',
    }

    translations[value] || value
  end
end
