# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_current_request_details
  before_action :authenticate
  before_action :set_sentry_context
  around_action :switch_locale

  private

  # Valida que haya un proveedor logueado
  def authenticate_provider
    authenticate

    redirect_to sign_in_path unless Current.user.provider?
  end

  def authenticate
    redirect_to sign_in_path unless perform_authentication
  end

  def require_no_authentication
    return unless perform_authentication

    flash[:notice] = t("flash.already_signed_in")
    redirect_to root_path
  end

  def perform_authentication
    Current.session ||= Session.find_by_id(cookies.signed[:session_token])
  end

  def switch_locale(&action)
    locale = params[:locale] || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def set_current_request_details
    Current.user_agent = request.user_agent
    Current.ip_address = request.ip
  end

  # Identify the user in Sentry without sending PII — the id is enough to
  # correlate reports, and set_user({}) clears it for anonymous requests.
  def set_sentry_context
    if (user = Current.user)
      Sentry.set_user(id: user.id, username: "User-#{user.id}")
    else
      Sentry.set_user({})
    end
  end
end
