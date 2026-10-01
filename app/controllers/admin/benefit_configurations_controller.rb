# frozen_string_literal: true

class Admin::BenefitConfigurationsController < Admin::InertiaController
  def index
    company = Current.user.admin.company

    @benefit_configurations = company.benefit_configurations
    @pending_base_subsidies = BenefitConfiguration.pending_base_subsidies_for company
    @base_subsidy = BenefitConfiguration.base_subsidy_for company
    @configurable_month = Calendar.new.configurable_month.strftime("%d/%m/%y")
  end

  def create
    company = Current.user.admin.company
    effective_from = Calendar.new.configurable_month
    benefit_configuration = nil

    # Hacer toda la acción como una transacción: No queremos borrar el beneficio que ya
    # está si no podemos crear uno nuevo.
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

      benefit_configuration = BenefitConfiguration.new_base_subsidy(
        created_by: Current.user,
        company:,
        effective_from:,
        subsidy_percentage: benefit_configuration_params[:subsidy_percentage],
        max_price: benefit_configuration_params[:max_voucher_price],
        limit: benefit_configuration_params[:monthly_voucher_limit]
      )

      raise ActiveRecord::Rollback unless benefit_configuration.save
    end

    if benefit_configuration.persisted?
      redirect_to admin_benefit_configurations_path, notice: t("flash.benefit_configuration_created")
    else
      errors_hash = {
        benefit_configuration: benefit_configuration.errors,
        benefit_rules: benefit_configuration.benefit_rules.map(&:errors)
      }

      redirect_back fallback_location: admin_benefit_configurations_path,
                    inertia: { errors: errors_hash }
    end
  end

  private

  def benefit_configuration_params
    params.expect(benefit_configuration: [ :subsidy_percentage, :monthly_voucher_limit, :max_voucher_price ])
  end
end
