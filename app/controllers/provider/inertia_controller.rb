# frozen_string_literal: true

class Provider::InertiaController < InertiaController
  skip_before_action :authenticate
  before_action -> { authenticate_role(:provider) }

  private

  def unauthenticated_path
    provider_sign_in_path
  end
end
