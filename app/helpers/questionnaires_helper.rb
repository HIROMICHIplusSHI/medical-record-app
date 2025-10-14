module QuestionnairesHelper
  # JSON配列データを人間が読みやすい形式に変換
  def format_json_field(field_value)
    return '' if field_value.blank?

    # 既に配列の場合
    if field_value.is_a?(Array)
      return field_value.join("\n")
    end

    # JSON文字列の場合
    begin
      parsed = JSON.parse(field_value)
      if parsed.is_a?(Array)
        parsed.join("\n")
      elsif parsed.is_a?(String)
        parsed
      else
        field_value
      end
    rescue JSON::ParserError
      # JSONパースに失敗した場合はそのまま表示
      field_value
    end
  end
end
