# frozen_string_literal: true

class Admin::ConsumersController < Admin::InertiaController
  def index
    @consumers = AdminConsumerSummary.rows_for(company)
  end

  # El find va sobre los empleados de la empresa del admin y no sobre Consumer:
  # pedir el de otra empresa tiene que ser un 404, no un empleado ajeno.
  def show
    @consumer = company.consumers.preload(:user, :company).find(params[:id])

    summary = AdminConsumerSummary.new(@consumer)
    @summary = summary.current_month
    @benefit_summary = OrderPricing.new(@consumer).summary
    @months = summary.months
  end

  private

  def company
    Current.user.admin.company
  end
end
