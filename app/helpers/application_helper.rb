module ApplicationHelper
  def flash_class(type)
    case type.to_sym
    when :notice, :success
      'bg-green-100 border border-green-400 text-green-700'
    when :alert, :error
      'bg-red-100 border border-red-400 text-red-700'
    else
      'bg-blue-100 border border-blue-400 text-blue-700'
    end
  end

  def dynamic_root_path
    if user_signed_in?
      current_user.admin? ? admin_root_path : user_root_path
    else
      new_user_session_path
    end
  end

  def unread_inquiry_count(user)
    return 0 unless user

    cache_key = "unread_inquiry_count_user_#{user.id}"

    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      if user.admin?
        # 管理者：未対応 OR 対応中でユーザーが最後に返信
        Inquiry.where(status: :open)
               .or(Inquiry.where(status: :in_progress, last_message_by: :user))
               .count
      else
        # ユーザー：管理者が最後に返信したお問い合わせ
        user.inquiries.where(last_message_by: :admin).count
      end
    end
  end

  def link_to_nav_item(text, path, &block)
    is_active = current_page?(path)
    classes = "px-3 py-2 rounded-md text-sm font-medium transition-colors #{
      is_active ? 'bg-blue-700' : 'hover:bg-blue-700'
    }"

    if block_given?
      link_to path, class: classes do
        capture(&block)
      end
    else
      link_to text, path, class: classes
    end
  end

  def link_to_mobile_nav_item(text, path, &block)
    is_active = current_page?(path)
    classes = "block px-3 py-2 rounded-md text-base font-medium transition-colors #{
      is_active ? 'bg-blue-700' : 'hover:bg-blue-700'
    }"

    if block_given?
      link_to path, class: classes do
        capture(&block)
      end
    else
      link_to text, path, class: classes
    end
  end

  def unread_indicator_for(inquiry, current_user)
    show_unread = if current_user.admin?
                    # 管理者：未対応 OR 対応中でユーザーが最後に返信
                    inquiry.open? || (inquiry.in_progress? && inquiry.user?)
                  else
                    # ユーザー：管理者が最後に返信
                    inquiry.admin?
                  end

    return unless show_unread

    content_tag(:span, 'NEW', class: 'inline-block px-2 py-0.5 text-xs font-semibold rounded bg-red-500 text-white',
                              title: '未読', 'aria-label': '未読')
  end
end
