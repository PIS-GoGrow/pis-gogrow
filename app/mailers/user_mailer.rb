# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def email_verification
    @user = params[:user]
    @signed_id = @user.generate_token_for(:email_verification)

    mail to: @user.email, subject: t(".subject")
  end

  def invitation
    @otp_code = params[:otp_code]
    @user = @otp_code.user
    @company = params[:company]
    @token = "#{@user.id}.#{@otp_code.code}"
    @company_token = @company.signed_id(purpose: :provider_invitation, expires_in: OtpCode::TTL.fetch("invitation"))

    mail to: @user.email, subject: t(".subject")
  end

  def password_reset_code
    @otp_code = params[:otp_code]
    @user = @otp_code.user
    @code = @otp_code.code
    @minutes = (OtpCode::TTL.fetch("password_reset") / 1.minute).to_i

    mail to: @user.email, subject: t(".subject")
  end
end
