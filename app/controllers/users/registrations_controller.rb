# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :configure_sign_up_params, only: [:create]

    # POST /resource
    # rubocop:disable Metrics/AbcSize
    def create
      build_resource(sign_up_params)

      # 規約同意チェックボックスが選択されている場合、タイムスタンプを設定
      resource.terms_accepted_at = Time.current if params[:user][:terms_accepted] == 'true'

      resource.privacy_accepted_at = Time.current if params[:user][:privacy_accepted] == 'true'

      resource.save
      yield resource if block_given?
      if resource.persisted?
        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    end
    # rubocop:enable Metrics/AbcSize

    protected

    # 規約同意・招待コードパラメータを許可
    def configure_sign_up_params
      devise_parameter_sanitizer.permit(:sign_up, keys: %i[terms_accepted privacy_accepted invitation_code_input])
    end
  end
end
