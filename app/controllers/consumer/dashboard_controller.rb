# frozen_string_literal: true

class Consumer::DashboardController < Consumer::InertiaController
  def index
    @role = params[:role]
  end
end
