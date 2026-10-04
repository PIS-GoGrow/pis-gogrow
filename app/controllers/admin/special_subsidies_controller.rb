# frozen_string_literal: true

class Admin::SpecialSubsidiesController < Admin::InertiaController
  def create
    special_subsidy = company.benefit_configurations.new(created_by: Current.user)

    save_and_redirect special_subsidy
  end

  def update
    save_and_redirect company.benefit_configurations.active.special.find(params[:id])
  end

  def destroy
    company.benefit_configurations.active.special.find(params[:id]).deactivate!(by: Current.user)

    redirect_to admin_benefit_configurations_path
  end

  private

  def company
    Current.user.admin.company
  end

  def save_and_redirect(special_subsidy)
    attributes = special_subsidy_params

    saved = special_subsidy.save_special_subsidy(
      by: Current.user,
      name: attributes[:name],
      subsidy_percentage: attributes[:subsidy_percentage],
      applies_to_all: attributes[:applies_to_all],
      consumer_ids: attributes[:consumer_ids],
      condition: attributes.fetch(:condition, {})
    )

    if saved
      redirect_to admin_benefit_configurations_path
    else
      redirect_back fallback_location: admin_benefit_configurations_path,
                    inertia: { errors: special_subsidy_errors(special_subsidy) }
    end
  end

  def special_subsidy_params
    params.expect(
      special_subsidy: [
        :name, :subsidy_percentage, :applies_to_all, consumer_ids: [],
        condition: [ :type, :min_years, :limit, :validity_amount, :validity_unit, :effective_from ]
      ]
    )
  end

  # Los errores vuelven con los nombres de los campos del formulario: la validez se
  # guarda como deadline_days o deadline_date según la condición.
  def special_subsidy_errors(special_subsidy)
    rule_errors = special_subsidy.benefit_rules.reject(&:marked_for_destruction?).flat_map { |rule| rule.errors.errors }
    own_errors = special_subsidy.errors.reject { |error| error.attribute.start_with?("benefit_rules") }

    (own_errors + rule_errors)
      .group_by { |error| { consumers: :consumer_ids, deadline_days: :validity_amount, deadline_date: :validity_amount }.fetch(error.attribute, error.attribute) }
      .transform_values { |errors| errors.map(&:message) }
  end
end
