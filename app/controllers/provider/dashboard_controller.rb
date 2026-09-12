# frozen_string_literal: true

class Provider::DashboardController < Provider::InertiaController
  def index
    @role = params[:role]
  end
end
