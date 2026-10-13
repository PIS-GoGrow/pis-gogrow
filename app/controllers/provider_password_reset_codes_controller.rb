# frozen_string_literal: true

class ProviderPasswordResetCodesController < InertiaController
  include Throttling
  include PasswordGrant

  skip_before_action :authenticate
  before_action :require_no_authentication
  before_action :require_pending_reset

  throttle "provider-reset-code-ip", to: 20, within: 1.minute, only: :create
  throttle "provider-reset-code-email", to: 10, within: 15.minutes, by: -> { session.dig(:password_reset, "email") }, only: :create

  def show
    @email = session[:password_reset]["email"]
    elapsed = Time.current.to_i - session[:password_reset]["sent_at"]
    @resend_in = [ OtpCode::RESEND_COOLDOWN.fetch("password_reset").to_i - elapsed, 0 ].max
  end

  def create
    user = User.find_by(email: session[:password_reset]["email"])

    if user&.provider? && OtpCode.verify(user, :password_reset, params[:code].to_s.strip)
      grant_password_change(user, :password_reset)
      session.delete(:password_reset)
      redirect_to edit_provider_password_reset_path
    else
      redirect_to provider_password_reset_code_path, inertia: { errors: { code: [ t("validations.invalid_code") ] } }
    end
  end

  private

  def require_pending_reset
    redirect_to provider_sign_in_path, alert: t("flash.password_reset_expired") unless session[:password_reset]
  end
end
