# frozen_string_literal: true

class Admin::DashboardController < Admin::InertiaController
  def index
    @role = params[:role]
  end
end
