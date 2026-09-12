# frozen_string_literal: true

class Admin::InertiaController < InertiaController
  before_action :set_role
  before_action :authenticate_admin

  private

  def set_role
    Current.role = "admin"
    cookies.signed[:last_role] = Current.role
  end
end

