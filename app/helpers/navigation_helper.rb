module NavigationHelper
  def link_to_nav_item(text, path, disabled: false)
    css_class = if disabled
                  'px-3 py-2 rounded-md text-sm font-medium text-gray-300 cursor-not-allowed'
                elsif current_page?(path)
                  'px-3 py-2 rounded-md text-sm font-medium bg-greige-100 text-accent-primary'
                else
                  'px-3 py-2 rounded-md text-sm font-medium text-greige-700 ' \
                    'hover:text-accent-primary hover:bg-greige-100 transition-colors'
                end

    if disabled
      content_tag(:span, text, class: css_class)
    else
      link_to text, path, class: css_class, 'aria-current': (current_page?(path) ? 'page' : nil)
    end
  end

  def link_to_mobile_nav_item(text, path, disabled: false)
    css_class = if disabled
                  'block px-3 py-2 rounded-md text-base font-medium text-gray-300 cursor-not-allowed'
                elsif current_page?(path)
                  'block px-3 py-2 rounded-md text-base font-medium bg-greige-100 text-accent-primary'
                else
                  'block px-3 py-2 rounded-md text-base font-medium text-greige-700 ' \
                    'hover:text-accent-primary hover:bg-greige-100 transition-colors'
                end

    if disabled
      content_tag(:span, text, class: css_class)
    else
      link_to text, path, class: css_class, 'aria-current': (current_page?(path) ? 'page' : nil)
    end
  end
end
