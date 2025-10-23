module UserDashboardHelper
  # カードスタイル用の左ボーダークラス
  def announcement_border_class(severity)
    case severity.to_sym
    when :info
      'border-blue-500'
    when :warning
      'border-yellow-500'
    when :critical
      'border-red-500'
    else
      'border-gray-400'
    end
  end

  def announcement_icon(severity)
    icon_class = announcement_icon_class(severity)
    icon_path = announcement_icon_path(severity)

    content_tag(:svg, class: "h-5 w-5 #{icon_class}", fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24') do
      tag.path('stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: icon_path)
    end
  end

  private

  def announcement_icon_class(severity)
    case severity.to_sym
    when :info then 'text-blue-500'
    when :warning then 'text-yellow-500'
    when :critical then 'text-red-500'
    else 'text-gray-500'
    end
  end

  def announcement_icon_path(severity)
    case severity.to_sym
    when :info
      'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z'
    when :warning
      'M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c' \
      '-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z'
    else
      # critical および unknown の場合、alert アイコンを表示
      'M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z'
    end
  end
end
