# frozen_string_literal: true

class Admin::BenefitConfigurationsController < Admin::InertiaController
  def index
    company = Current.user.admin.company

    @benefit_configurations = company.benefit_configurations.ordered
    @current_benefit_configuration = BenefitConfiguration.current_for(company)
  end

  def create
    company = Current.user.admin.company
    effective_from = next_period_effective_from

    # RRHH ya vio que hay un cambio programado (todavia no vigente) para el
    # proximo periodo y eligio explicitamente reemplazarlo por este nuevo
    # -- el front se lo pregunta antes de mandar este parametro (ver
    # "Alert" de conflicto en edit-benefit-configuration-form.tsx). Solo
    # se borra la fila que todavia no entro en vigencia, nunca una ya
    # aplicada.
    if ActiveModel::Type::Boolean.new.cast(params[:replace_pending])
      company.benefit_configurations.where(effective_from: effective_from).destroy_all
    end

    benefit_configuration = company.benefit_configurations.new(benefit_configuration_params)
    benefit_configuration.created_by = Current.user
    benefit_configuration.effective_from = effective_from

    if benefit_configuration.save
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
