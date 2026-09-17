# frozen_string_literal: true

class Admin::BenefitConfigurationsController < Admin::InertiaController
  def index
    company = Current.user.admin.company

    @benefit_configurations = company.benefit_configurations.ordered
    @current_benefit_configuration = BenefitConfiguration.current_for(company)
  end

  def create
    company = Current.user.admin.company
    benefit_configuration = company.benefit_configurations.new(benefit_configuration_params)
    benefit_configuration.created_by = Current.user

    if benefit_configuration.save
      redirect_to admin_benefit_configurations_path, notice: t("flash.benefit_configuration_created")
    else
      redirect_back fallback_location: admin_benefit_configurations_path, inertia: { errors: benefit_configuration.errors }
    end
  end

  private

  def benefit_configuration_params
    params.expect(benefit_configuration: [ :subsidy_percentage, :monthly_voucher_limit, :effective_from ])
  end
end
