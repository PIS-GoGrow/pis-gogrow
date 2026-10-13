# frozen_string_literal: true

class ProviderPasswordResetsController < InertiaController
  include Throttling
  include PasswordGrant
  include ProviderSignIn

  skip_before_action :authenticate
  before_action :require_no_authentication

  throttle "provider-reset-request-ip", to: 10, within: 1.minute, only: :create
  throttle "provider-reset-request-email", to: 5, within: 1.hour, by: -> { params[:email].to_s.strip.downcase }, only: :create

  def create
    email = params[:email].to_s.strip.downcase
    return redirect_back_or_to(provider_sign_in_path, inertia: { errors: { email: [ t("validations.invalid_email") ] } }) unless email.match?(URI::MailTo::EMAIL_REGEXP)

    user = User.find_by(email: email)
    if user&.provider? && (otp = OtpCode.issue(user, :password_reset))
      UserMailer.with(otp_code: otp).password_reset_code.deliver_later
    end

    session[:password_reset] = { "email" => email, "sent_at" => Time.current.to_i }
    redirect_to provider_password_reset_code_path
  end

  def edit
    user = granted_user(:password_reset)
    return redirect_to provider_sign_in_path, alert: t("flash.password_reset_expired") unless user

    @email = user.email
  end

  def update
    user = granted_user(:password_reset)
    return redirect_to provider_sign_in_path, alert: t("flash.password_reset_expired") unless user

    user.assign_attributes(params.permit(:password, :password_confirmation).merge(verified: true))

    if user.save(context: :provider_password)
      start_provider_session(user)
      redirect_to provider_dashboard_path, notice: t("flash.signed_in")
    else
      redirect_to edit_provider_password_reset_path, inertia: { errors: user.errors }
    end
  end
end
