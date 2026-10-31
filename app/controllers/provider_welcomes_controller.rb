# frozen_string_literal: true

class ProviderWelcomesController < InertiaController
  include Throttling

  skip_before_action :authenticate
  before_action :require_no_authentication

  throttle "provider-welcome-ip", to: 20, within: 1.minute

  def show
    user_id, code = params[:token].to_s.split(".", 2)
    user = User.find_by(id: user_id)
    company = Company.find_signed(params[:company], purpose: :provider_invitation)

    unless company && user&.provider? && !user.verified? && OtpCode.check(user, :invitation, code)
      return redirect_to provider_sign_in_path, alert: t("flash.invitation_invalid")
    end

    @username = user.name
    @company_name = company.name
    @invitation_path = provider_invitation_path(token: params[:token])
  end
end
