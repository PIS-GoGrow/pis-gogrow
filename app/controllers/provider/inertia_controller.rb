# frozen_string_literal: true

class Provider::InertiaController < InertiaController
  before_action :set_role
  before_action :authenticate_provider

  private

  def set_role
    Current.role = "provider"
    cookies.signed[:last_role] = Current.role
  end
end
