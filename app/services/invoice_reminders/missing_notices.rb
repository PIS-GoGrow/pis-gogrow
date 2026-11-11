# frozen_string_literal: true

# Avisa a RR. HH. de los períodos cerrados con deuda que el proveedor todavía no
# facturó. Hay un aviso por cuenta y admin: si RR. HH. lo cierra, no vuelve.
module InvoiceReminders
  class MissingNotices
    EVENT = :hr_invoice_missing

    class << self
      def remind!(date: Date.current)
        Account.companies
          .where(month: ...date.beginning_of_month)
          .where.not(amount: ..0)
          .preload(:payments, :invoices, provider: :user, owner: { admins: :user })
          .select { it.collection_status != "approved" && it.invoices.none? { |invoice| invoice.pending? || invoice.approved? } }
          .each { notify(it) }
      end

      def close(account)
        account.owner.admins.each do |admin|
          Notification.close_by(event: EVENT, notifiable: account, user: admin.user)
        end
      end

      private

      def notify(account)
        account.owner.admins.map(&:user).each do |user|
          next if user.notifications.exists?(event: EVENT, notifiable: account)

          Notifier.call(
            event_key: EVENT,
            user:,
            notifiable: account,
            description_data: {
              provider: account.provider.user.name,
              period: I18n.l(account.month, format: :month_name_year)
            }
          )
        end
      end
    end
  end
end
