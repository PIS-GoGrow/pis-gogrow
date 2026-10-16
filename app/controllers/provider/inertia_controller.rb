# frozen_string_literal: true

class Provider::InertiaController < InertiaController
  skip_before_action :authenticate
  before_action -> { authenticate_role(:provider) }
  before_action :require_onboarding

  private

  def require_onboarding
    return if Current.user.provider&.onboarded?

    redirect_to provider_onboarding_path
  end

  def unauthenticated_path
    provider_sign_in_path
  end
end
