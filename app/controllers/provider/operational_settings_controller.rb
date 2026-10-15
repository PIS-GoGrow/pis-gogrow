# frozen_string_literal: true

class Provider::OperationalSettingsController < Provider::InertiaController
  def show
    @provider = Current.user.provider
    @order_deadline_passed_today = @provider.order_deadline_passed_today?
    @closures = @provider.closures.upcoming
    @today = Date.current.iso8601
  end
end
