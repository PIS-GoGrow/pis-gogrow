# frozen_string_literal: true

class Admin::ConsumersController < Admin::InertiaController
  def index
    month = selected_month.beginning_of_month

    @consumers = AdminConsumerSummary.rows_for(company, month:)
    @filter = params[:filter].presence_in(%w[all pending]) || "all"
    @month = month.strftime("%Y-%m")
    @current_month = Date.current.strftime("%Y-%m")
    @months = month_options(AdminMonthlySummary.new(company, month).months)
  end

  # El find va sobre los empleados de la empresa del admin y no sobre Consumer:
  # pedir el de otra empresa tiene que ser un 404, no un empleado ajeno.
  def show
    @consumer = company.consumers.preload(:user, :company).find(params[:id])

    summary = AdminConsumerSummary.new(@consumer)
    @summary = summary.current_month
    @benefit_summary = Orders::Pricing.new(@consumer).summary
    @months = summary.months
    @debt_reminder = debt_reminder_for(@consumer)
  end

  private

  # Estado del botón de recordar el pago: la pantalla necesita saber si se puede
  # mandar y, si no, por qué.
  def debt_reminder_for(consumer)
    eligibility = DebtReminders::EmployeeEligibility.new(consumer:)

    {
      eligible: eligibility.eligible?,
      amount: eligibility.amount.to_f,
      remaining: eligibility.remaining,
      next_available_at: DateFormat.long_with_time(eligibility.next_available_at&.in_time_zone(Time.zone), inline: true),
      blocked_reason: eligibility.reason&.to_s
    }
  end

  def company
    Current.user.admin.company
  end
end
