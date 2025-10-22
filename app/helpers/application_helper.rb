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

    if user.admin?
      # 管理者：未対応のお問い合わせ数
      Inquiry.where(status: :open).count
    else
      # ユーザー：現状では0（Phase 6-B-4で実装予定）
      0
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
end
