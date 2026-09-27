# frozen_string_literal: true

class Admin::BenefitConfigurationsController < Admin::InertiaController
  def index
    company = Current.user.admin.company

    @benefit_configurations = company.benefit_configurations
    @pending_base_subsidy = BenefitConfiguration.base_subsidy_for company, effective_from: next_period_effective_from
    @base_subsidy = BenefitConfiguration.base_subsidy_for company

    @pending_base_subsidy = @pending_base_subsidy == @base_subsidy ? nil : @pending_base_subsidy
  end

  def create
    company = Current.user.admin.company
    effective_from = next_period_effective_from
    benefit_configuration = nil
    
    ActiveRecord::Base.transaction do
      # RRHH ya vio que hay un cambio programado (todavia no vigente) para el
      # proximo periodo y eligio explicitamente reemplazarlo por este nuevo
      # -- el front se lo pregunta antes de mandar este parametro (ver
      # "Alert" de conflicto en edit-benefit-configuration-form.tsx). Solo
      # se borra la fila que todavia no entro en vigencia, nunca una ya
      # aplicada.
      if ActiveModel::Type::Boolean.new.cast(params[:replace_pending])
        company.benefit_configurations
               .monthly
               .where(benefit_rules: { effective_from: effective_from })
               .destroy_all
      end

      benefit_configuration = company.benefit_configurations.new(
        created_by: Current.user,
        name: "Subsidio base",
        subsidy_percentage: benefit_configuration_params[:subsidy_percentage]
      )
      benefit_configuration.benefit_rules.new(
        type: MonthlyBenefit.name,
        effective_from:,
        max_price: benefit_configuration_params[:max_voucher_price],
        limit: benefit_configuration_params[:monthly_voucher_limit]
      )

      raise ActiveRecord::Rollback unless benefit_configuration.save
    end

    if benefit_configuration.persisted?
      redirect_to admin_benefit_configurations_path, notice: t("flash.benefit_configuration_created")
    else
      redirect_back fallback_location: admin_benefit_configurations_path, inertia: { errors: benefit_configuration.errors }
    end
  end

  private

  def benefit_configuration_params
    params.expect(benefit_configuration: [ :subsidy_percentage, :monthly_voucher_limit, :max_voucher_price ])
  end

  # RRHH ya no elige la fecha de vigencia: el cambio se aplica siempre a
  # partir del primer día del próximo período (mes), como quedó definido en
  # el Figma ("Los cambios se aplicarán en el próximo período").
  def next_period_effective_from
    Date.current.next_month.beginning_of_month
  end
end
