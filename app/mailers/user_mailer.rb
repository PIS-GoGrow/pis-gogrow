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
    serving_food = Rails.root.join("public/serving-food.png")
    gogrow_logo = Rails.root.join("public/gogrow-logo.png")

    attachments.inline["serving-food.png"] = serving_food.read if serving_food.file?
    attachments.inline["gogrow-logo.png"] = gogrow_logo.read if gogrow_logo.file?
  end
end
