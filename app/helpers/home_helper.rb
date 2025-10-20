module HomeHelper
  def announcement_alert_class(severity)
    case severity.to_sym
    when :info
      'bg-blue-50 border border-blue-200'
    when :warning
      'bg-yellow-50 border border-yellow-200'
    when :critical
      'bg-red-50 border border-red-200'
    else
      'bg-gray-50 border border-gray-200'
    end
  end

  def announcement_text_class(severity)
    case severity.to_sym
    when :info
      'text-blue-800'
    when :warning
      'text-yellow-800'
    when :critical
      'text-red-800'
    else
      'text-gray-800'
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
    when :info then 'text-blue-400'
    when :warning then 'text-yellow-400'
    when :critical then 'text-red-400'
    else 'text-gray-400'
    end
  end

  def announcement_icon_path(severity)
    case severity.to_sym
    when :info
      'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z'
    when :warning
      'M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c' \
      '-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z'
    when :critical
      'M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z'
    else
      'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z'
    end
  end

  def announcement_dismiss_class(severity)
    case severity.to_sym
    when :info
      'text-blue-500 hover:bg-blue-100 focus:ring-blue-600'
    when :warning
      'text-yellow-500 hover:bg-yellow-100 focus:ring-yellow-600'
    when :critical
      'text-red-500 hover:bg-red-100 focus:ring-red-600'
    else
      'text-gray-500 hover:bg-gray-100 focus:ring-gray-600'
    end
  end
end
