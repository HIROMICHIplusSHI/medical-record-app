module ApplicationHelper
  def flash_class(type)
    case type.to_sym
    when :notice, :success
      'bg-accent-success/10 border border-accent-success text-accent-success'
    when :alert, :error
      'bg-accent-danger/10 border border-accent-danger text-accent-danger'
    else
      'bg-accent-info/10 border border-accent-info text-accent-info'
    end
  end

  def dynamic_root_path
    if user_signed_in?
      current_user.admin? ? admin_root_path : user_dashboard_path
    else
      root_path
    end
  end

  def unread_inquiry_count(user)
    return 0 unless user

    cache_key = "unread_inquiry_count_user_#{user.id}"

    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      if user.admin?
        # 管理者：admin_read_atがNULL OR ユーザーが送った最後のメッセージがadmin_read_atより新しい
        Inquiry.joins(:inquiry_messages)
               .joins('INNER JOIN users ON inquiry_messages.user_id = users.id')
               .where(
                 'admin_read_at IS NULL OR (users.role = ? AND inquiry_messages.created_at > admin_read_at)',
                 User.roles[:user]
               )
               .distinct
               .count
      else
        # ユーザー：user_read_atがNULL OR 管理者が送った最後のメッセージがuser_read_atより新しい
        user.inquiries
            .joins(:inquiry_messages)
            .joins('INNER JOIN users ON inquiry_messages.user_id = users.id')
            .where(
              'user_read_at IS NULL OR (users.role = ? AND inquiry_messages.created_at > user_read_at)',
              User.roles[:admin]
            )
            .distinct
            .count
      end
    end
  end

  def unread_indicator_for(inquiry, current_user)
    if current_user.admin?
      # 管理者：ユーザーが送った最後のメッセージを確認
      last_user_message = inquiry.inquiry_messages
                                 .joins(:user)
                                 .where(users: { role: :user })
                                 .order(created_at: :desc)
                                 .first
      return unless last_user_message

      show_unread = inquiry.admin_read_at.nil? || last_user_message.created_at > inquiry.admin_read_at
    else
      # ユーザー：管理者が送った最後のメッセージを確認
      last_admin_message = inquiry.inquiry_messages
                                  .joins(:user)
                                  .where(users: { role: :admin })
                                  .order(created_at: :desc)
                                  .first
      return unless last_admin_message

      show_unread = inquiry.user_read_at.nil? || last_admin_message.created_at > inquiry.user_read_at
    end

    return unless show_unread

    content_tag(
      :span, 'NEW',
      class: 'inline-block px-2 py-0.5 text-xs font-semibold rounded bg-accent-danger text-white',
      title: '未読', 'aria-label': '未読'
    )
  end

  def render_markdown(file_path)
    markdown_content = File.read(Rails.root.join(file_path))
    Kramdown::Document.new(markdown_content).to_html.html_safe
  end
end
