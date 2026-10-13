# frozen_string_literal: true

class Admin::DashboardController < Admin::InertiaController
  def index
    summary = AdminMonthlySummary.new(Current.user.admin.company, selected_month)

    @today = I18n.l(Date.current, format: "%A %-d de %B").capitalize
    @month = summary.month.strftime("%Y-%m")
    @current_month = Date.current.strftime("%Y-%m")
    @months = summary.months.map { { key: it.strftime("%Y-%m"), label: I18n.l(it, format: :month_name_year) } }
    @summary = summary.to_h
    @payment_month = I18n.l(summary.payments_month, format: "%B").downcase
    @payments = summary.payments.map(&:to_h)
    @debtors = summary.debtors
  end
end
