# frozen_string_literal: true

class Admin::DebtAlertsController < Admin::InertiaController
  def update
    company = Current.user.admin.company

    if company.update(params.expect(company: [ :debt_alert_threshold ]))
      company.check_debt_alerts! if company.saved_change_to_debt_alert_threshold?
      redirect_to admin_benefit_configurations_path, notice: t("flash.debt_alert_updated")
    else
      redirect_back fallback_location: admin_benefit_configurations_path,
                    inertia: { errors: company.errors }
    end
  end
end
