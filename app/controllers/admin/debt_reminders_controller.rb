# frozen_string_literal: true

class Admin::DebtRemindersController < Admin::InertiaController
  def create
    consumer = Current.user.admin.company.consumers.find(params[:consumer_id])
    DebtReminders::EmployeeRequest.call(consumer:, requested_by: Current.user)
    redirect_back fallback_location: admin_consumer_path(consumer), status: :see_other
  rescue DebtReminders::Request::Ineligible => e
    reject(t("validations.debt_reminder_#{e.reason}"))
  rescue DebtReminders::Request::CreationFailed
    reject(t("validations.debt_reminder_failed"))
  end

  private

  def reject(message)
    redirect_back fallback_location: admin_consumers_path,
                  inertia: { errors: { debt_reminder: [ message ] } },
                  status: :see_other
  end
end
