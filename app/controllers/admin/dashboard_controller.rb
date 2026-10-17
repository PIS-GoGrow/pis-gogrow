# frozen_string_literal: true

class Admin::DashboardController < Admin::InertiaController
  def index
    company = Current.user.admin.company
    summary = AdminMonthlySummary.new(company, selected_month)

    @today = I18n.l(Date.current, format: "%A %-d de %B").capitalize
    @month = summary.month.strftime("%Y-%m")
    @current_month = Date.current.strftime("%Y-%m")
    @months = month_options(summary.months)
    @summary = summary.to_h
    @consumption = AdminConsumptionDetail.new(company, summary.month).to_h
    @payment_month = I18n.l(summary.payments_month, format: "%B").downcase
    @payments = summary.payments.map(&:to_h)
    @debtors = summary.debtors
  end
end
