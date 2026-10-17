# frozen_string_literal: true

class ProviderInvitationsController < InertiaController
  include Throttling
  include PasswordGrant
  include ProviderSignIn

  skip_before_action :authenticate
  before_action :require_no_authentication

  throttle "provider-invitation-ip", to: 20, within: 1.minute

  def show
    return accept_token if params[:token].present?

    user = granted_user(:invitation)
    return redirect_to provider_sign_in_path, alert: t("flash.invitation_invalid") unless user

    @email = user.email
  end

  def update
    user = granted_user(:invitation)
    return redirect_to provider_sign_in_path, alert: t("flash.invitation_invalid") unless user && OtpCode.pending?(user, :invitation)

    if set_password(user)
      OtpCode.consume(user, :invitation)
      start_provider_session(user)
      redirect_to provider_onboarding_path, notice: t("flash.signed_in")
    else
      redirect_to provider_invitation_path, inertia: { errors: user.errors }
    end
  end

  private

  def accept_token
    user_id, code = params[:token].to_s.split(".", 2)
    user = User.find_by(id: user_id)

    if user&.provider? && !user.verified? && OtpCode.check(user, :invitation, code)
      grant_password_change(user, :invitation)
      redirect_to provider_invitation_path
    else
      redirect_to provider_sign_in_path, alert: t("flash.invitation_invalid")
    end
  end

  def set_password(user)
    user.assign_attributes(params.permit(:password, :password_confirmation).merge(verified: true))
    user.save(context: :provider_password)
  end
end
