# frozen_string_literal: true

class Provider::DashboardController < Provider::InertiaController
  def index
    @provider = Current.user.provider
  end
end
