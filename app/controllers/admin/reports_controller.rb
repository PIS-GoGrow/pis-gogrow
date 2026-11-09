# frozen_string_literal: true

class Admin::ReportsController < Admin::InertiaController
  include SelectedPeriod

  def index
    company = Current.user.admin.company
    range = select_period(AdminReportsSummary.first_delivery_date(company))
    summary = AdminReportsSummary.new(company, range)

    @summary = {
      adhesion: summary.adhesion,
      participants: summary.participants_count,
      employees: summary.employees_count,
      orders: summary.orders_count,
      meals: summary.meals,
      company_amount: summary.company_amount.to_f,
      employee_amount: summary.employee_amount.to_f
    }
    @providers = summary.by_provider.map do
      { id: it.provider_id, name: it.name, orders: it.orders_count, meals: it.meals, company_amount: it.company_amount.to_f }
    end
  end
end
