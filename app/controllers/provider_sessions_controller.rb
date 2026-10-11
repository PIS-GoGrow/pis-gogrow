# frozen_string_literal: true

class ProviderSessionsController < InertiaController
  include Throttling

  skip_before_action :authenticate
  before_action :require_no_authentication

  throttle "provider-sign-in-ip", to: 20, within: 1.minute, only: :create
  throttle "provider-sign-in-email", to: 10, within: 15.minutes, by: -> { params[:email].to_s.strip.downcase }, only: :create

  def new
  end

  def create
    user = User.authenticate_by(email: params[:email], password: params[:password])

    if user&.provider? && user.verified?
      reset_session
      session = user.sessions.create!(role: :provider)
      cookies.signed.permanent[:session_token] = { value: session.id, httponly: true }

      redirect_to provider_dashboard_path, notice: t("flash.signed_in")
    else
      redirect_to provider_sign_in_path, alert: t("flash.incorrect_credentials")
    end
  end
end
