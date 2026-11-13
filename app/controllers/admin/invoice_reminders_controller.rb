# frozen_string_literal: true

class Admin::InvoiceRemindersController < Admin::InertiaController
  def create
    account = Current.user.admin.company.accounts.find(params[:payment_id])
    InvoiceReminders::Request.call(account:, requested_by: Current.user)

    redirect_back fallback_location: admin_payments_path,
                  notice: t("flash.invoice_reminder_sent", provider: account.provider.user.name),
                  status: :see_other
  rescue InvoiceReminders::Request::Ineligible => e
    reject(t("validations.invoice_reminder_#{e.reason}"))
  rescue InvoiceReminders::Request::CreationFailed
    reject(t("validations.invoice_reminder_failed"))
  end

  private

  def reject(message)
    redirect_back fallback_location: admin_payments_path, alert: message, status: :see_other
  end
end
