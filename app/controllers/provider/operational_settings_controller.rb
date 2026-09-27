# frozen_string_literal: true

class Provider::OperationalSettingsController < Provider::InertiaController
  def show
    @provider = Current.user.provider
  end
end
