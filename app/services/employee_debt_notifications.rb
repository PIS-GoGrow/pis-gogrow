# frozen_string_literal: true

# Avisa a RR.HH. de los empleados que le deben a un proveedor desde hace más de
# un mes. Hay un aviso por proveedor y período, no por empleado, y llega a todos
# los admins de la empresa. Cuelga de la cuenta de la empresa con ese proveedor
# en ese período, que es única, así que el índice de Notification no admite dos
# avisos activos del mismo grupo.

class EmployeeDebtNotifications
  EVENT = :employee_debt_overdue

  class << self
    # Un mes cuenta como deuda vieja cuando vence el pago del mes siguiente
    def remind!(date: Date.current)
      groups = debt_groups(date)

      groups.each { |anchor, debts| sync(anchor, debts, create_on: date) }
      close_resolved(except: groups.keys)
    end

    # Actualiza o cierra el aviso cuando hay un pago de un empleado que estaba en deuda.
    # Con renotify (un rechazo), si el mes ya es deuda vieja, vuelve a crear el aviso cerrado.
    def refresh(account, renotify: false)
      return unless account.owner_type == "Consumer"

      anchor = anchors_for([ account ]).values.first
      return unless anchor

      consumers = Consumer.where(company_id: account.owner.company_id)
      debts = unpaid(
        Account.where(owner_type: "Consumer", owner_id: consumers.select(:id), provider_id: account.provider_id, month: account.month)
      )

      sync(anchor, debts, create_on: nil, renotify: renotify && Date.current > account.due_date.next_month)
    end

    private

    def debt_groups(date)
      overdue = unpaid(Account.where(owner_type: "Consumer", month: ..(date.beginning_of_month - 2.months)))
        .select { date > it.due_date.next_month }
      return {} if overdue.empty?

      anchors = anchors_for(overdue)

      overdue.group_by { [ it.owner.company_id, it.provider_id, it.month ] }
             .filter_map { |key, debts| [ anchors[key], debts ] if anchors[key] }
             .to_h
    end

    # Deudas de empleados: sin pago aprobado ni comprobante en revisión.
    def unpaid(scope)
      scope.pending
           .preload(:payments, provider: :user, owner: :user)
           .select { it.collection_status.in?(%w[pending rejected partial]) }
    end

    def anchors_for(accounts)
      Account.where(
        owner_type: "Company",
        owner_id: accounts.map { it.owner.company_id }.uniq,
        provider_id: accounts.map(&:provider_id).uniq,
        month: accounts.map(&:month).uniq
      ).preload(owner: { admins: :user }).index_by { [ it.owner_id, it.provider_id, it.month ] }
    end

    def sync(anchor, debts, create_on:, renotify: false)
      anchor.owner.admins.map(&:user).each do |user|
        active = user.notifications.active.find_by(event: EVENT, notifiable: anchor)

        if debts.empty?
          active&.close!
        elsif active
          update_description(active, debts)
        elsif renotify || (create_on && new_notice_due?(user, anchor, create_on))
          Notifier.call(event_key: EVENT, user:, notifiable: anchor, description_data: description_data(debts))
        end
      end
    end

    def update_description(notification, debts)
      description = I18n.t!("notifications.#{EVENT}.description", **description_data(debts))
      notification.update!(description:) unless notification.description == description
    end

    def description_data(debts)
      first = debts.min_by { it.owner.user.name }

      {
        count: debts.size,
        employee: first.owner.user.name,
        provider: first.provider.user.name,
        period: I18n.l(first.month, format: :month_name_year).downcase,
        amount: Account.format_amount(debts.sum { it.amount.to_d })
      }
    end

    def new_notice_due?(user, anchor, date)
      last = user.notifications.where(event: EVENT, notifiable: anchor).maximum(:created_at)
      last.nil? || last.to_date <= date - 1.month
    end

    def close_resolved(except:)
      Notification.active
                  .where(event: EVENT, notifiable_type: "Account")
                  .where.not(notifiable_id: except.map(&:id))
                  .find_each(&:close!)
    end
  end
end
