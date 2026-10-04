# frozen_string_literal: true

class Admin::DashboardController < Admin::InertiaController
  def index
    @today = I18n.l(Date.current, format: "%A %-d de %B").capitalize
    @payment_month = I18n.l(Date.current, format: "%B").downcase
  end
end
