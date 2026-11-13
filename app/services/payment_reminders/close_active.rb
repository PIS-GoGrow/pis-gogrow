# frozen_string_literal: true

module PaymentReminders
  class CloseActive
    EVENTS = %w[payment_available payment_due_soon].freeze

    # El recordatorio que manda el proveedor a mano reclama una deuda, no un pago
    # por hacer, así que se cierra recién cuando el comprobante queda aprobado: si
    # se cerrara al subirlo, un rechazo dejaría al empleado sin aviso y al
    # proveedor esperando los tres días de espera para volver a reclamarle.
    SETTLED_EVENTS = %w[debt_payment_reminder].freeze

    def self.call(account:, settled: false)
      return unless account.owner_type == "Consumer"

      events = settled ? EVENTS + SETTLED_EVENTS : EVENTS

      account.owner.user.notifications
             .active
             .where(event: events, notifiable: account)
             .find_each(&:close!)
    end
  end
end
