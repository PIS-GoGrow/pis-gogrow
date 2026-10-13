# frozen_string_literal: true

# Avisa a RR.HH. sobre el pago del subsidio que la empresa le debe a cada
# proveedor, que vive en la cuenta con owner Company. Los avisos llegan a todos
# los admins de la empresa y cuelgan de la cuenta, así que hay uno por proveedor
# y período.
#
# Ver docs/notificaciones.md
class CompanyPaymentNotifications
  UPCOMING_NOTICE = 3.days
  # Los que piden subir un comprobante: se resuelven cuando RR.HH. sube uno.
  PENDING_PAYMENT_EVENTS = %i[company_payment_upcoming company_payment_overdue company_payment_rejected].freeze

  class << self
    # Recorre los períodos cerrados sin comprobante. Una cuenta con el último
    # pago rechazado ya tiene su propio aviso, por eso solo se miran las pending.
    def remind!(date: Date.current)
      Account.companies
        .where(month: ...date.beginning_of_month)
        .where.not(amount: ..0)
        .preload(:payments, provider: :user, owner: { admins: :user })
        .select { it.collection_status == "pending" && date >= it.due_date - UPCOMING_NOTICE }
        .each { remind(it, date) }
    end

    def payment_status_changed(payment)
      account = payment.account

      admin_users(account).each do |user|
        case payment.status
        when "submitted"
          close_pending_payment(account, user)
        when "approved"
          close_pending_payment(account, user)
          notify(:company_payment_approved, account, user)
        when "rejected"
          notify(:company_payment_rejected, account, user)
        end
      end
    end

    private

    # Al vencer, el aviso de que se aproxima se reemplaza por el de vencido.
    def remind(account, date)
      overdue = date > account.due_date

      admin_users(account).each do |user|
        if overdue
          Notification.close_by(event: :company_payment_upcoming, notifiable: account, user:)
          notify(:company_payment_overdue, account, user)
        else
          notify(:company_payment_upcoming, account, user)
        end
      end
    end

    def close_pending_payment(account, user)
      PENDING_PAYMENT_EVENTS.each do |event|
        Notification.close_by(event:, notifiable: account, user:)
      end
    end

    # El índice único no admite dos avisos activos del mismo evento para una
    # cuenta, y Notifier solo rescata errores de validación.
    def notify(event, account, user)
      return if user.notifications.active.exists?(event:, notifiable: account)

      Notifier.call(event_key: event, user:, notifiable: account, description_data: description_data(account))
    end

    def description_data(account)
      {
        company: account.owner.name,
        provider: account.provider.user.name,
        period: I18n.l(account.month, format: :month_name_year).downcase,
        amount: account.formatted_amount,
        due_date: I18n.l(account.due_date)
      }
    end

    def admin_users(account)
      account.owner.admins.map(&:user)
    end
  end
end
