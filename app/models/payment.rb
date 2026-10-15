# frozen_string_literal: true

class Payment < ApplicationRecord
  enum :status, { pending: 0, submitted: 1, approved: 2, rejected: 3 }, default: :pending

  belongs_to :account
  belongs_to :provider, optional: true

  has_one_attached :receipt

  before_validation :clear_rejection_reason, if: :submitted?
  after_commit :notify_receipt_submitted, if: -> { saved_change_to_status? && submitted? }
  after_commit :check_debt_alert, if: -> { account.owner.is_a?(Consumer) && (destroyed? || saved_change_to_status?) }
  after_commit :notify_company_admins, on: [ :create, :update ], if: -> { saved_change_to_status? && account.company? }

  validates :rejection_reason, presence: true, if: :rejected?

  validate :receipt_is_attached_when_submitted
  validate :receipt_has_allowed_type
  validate :receipt_is_within_size_limit

  after_update_commit :close_debt_reminder, if: -> { saved_change_to_status? && approved? }
  after_save_commit :close_automatic_payment_reminders,
                    if: :should_close_automatic_payment_reminders?

  def approve
    transaction do
      updated = update(status: :approved, rejection_reason: nil)

      if updated && account.company?
        account.invoices.pending.first&.approved!
      end

      updated
    end
  end

  def reject_with(reason)
    update(status: :rejected, rejection_reason: reason)
  end

  private

  # Un comprobante reenviado es el mismo pago, y solo puede haber una
  # notificación activa por pago.
  def notify_receipt_submitted
    user = account.provider.user
    return unless user

    Notification.close_by(event: "payment_receipt_submitted", notifiable: self, user:)
    Notifier.call(
      event_key: :payment_receipt_submitted,
      user:,
      notifiable: self,
      description_data: {
        payer: account.owner.is_a?(Consumer) ? account.owner.user.name : account.owner.name,
        month: I18n.l(account.month, format: "%B %Y")
      }
    )
  end

  def check_debt_alert
    account.owner.check_debt_alert!
  end

  # El recordatorio que manda Recursos Humanos es por toda la deuda vencida del
  # empleado, así que se cierra recién cuando no le queda ninguna.
  def close_debt_reminder
    owner = account.owner

    DebtReminders::EmployeeRequest.close_if_settled(owner) if owner.is_a?(Consumer)
  end

  def clear_rejection_reason
    self.rejection_reason = nil
  end

  def notify_company_admins
    CompanyPaymentNotifications.payment_status_changed(self)
  end

  def receipt_is_attached_when_submitted
    errors.add(:receipt, :required) if submitted? && !receipt.attached?
  end

  def receipt_has_allowed_type
    return unless receipt.attached?
    return if receipt.blob.content_type.in?([ "application/pdf", "image/jpeg", "image/png" ])

    errors.add(:receipt, :invalid_content_type)
  end

  def receipt_is_within_size_limit
    return unless receipt.attached?
    return unless receipt.blob.byte_size > 10.megabytes

    errors.add(:receipt, :too_large)
  end

  def should_close_automatic_payment_reminders?
    saved_change_to_status? && (submitted? || approved?)
  end

  def close_automatic_payment_reminders
    PaymentReminders::CloseActive.call(account:)
  end
end

# == Schema Information
#
# Table name: payments
#
#  id               :bigint           not null, primary key
#  rejection_reason :text
#  status           :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  provider_id      :bigint
#
# Indexes
#
#  index_payments_on_account_id   (account_id)
#  index_payments_on_provider_id  (provider_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (provider_id => providers.id)
