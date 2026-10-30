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

    attach_branding_images

    mail to: @user.email, subject: t(".subject")
  end

  def password_reset_code
    @otp_code = params[:otp_code]
    @user = @otp_code.user
    @code = @otp_code.code
    @minutes = (OtpCode::TTL.fetch("password_reset") / 1.minute).to_i

    attach_branding_images

    mail to: @user.email, subject: t(".subject")
  end

  private

  def attach_branding_images
    attachments.inline["serving-food.png"] = Rails.root.join("public/serving-food.png").read
    attachments.inline["gogrow-logo.png"] = Rails.root.join("public/gogrow-logo.png").read
  end
end
