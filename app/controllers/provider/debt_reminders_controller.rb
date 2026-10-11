# frozen_string_literal: true

class Provider::DebtRemindersController < Provider::InertiaController
  def create
    account = Current.user.provider.accounts.find(params[:collection_id])
    DebtReminders::Request.call(account:, requested_by: Current.user)
    redirect_back fallback_location: provider_collections_path, status: :see_other
  rescue DebtReminders::Request::Ineligible => e
    redirect_back fallback_location: provider_collections_path,
                  inertia: { errors: { debt_reminder: [ t("validations.debt_reminder_#{e.reason}") ] } },
                  status: :see_other
  rescue DebtReminders::Request::CreationFailed
    redirect_back fallback_location: provider_collections_path,
                  inertia: { errors: { debt_reminder: [ t("validations.debt_reminder_failed") ] } },
                  status: :see_other
  end
end
