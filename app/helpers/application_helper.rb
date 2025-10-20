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
end
