# frozen_string_literal: true

# Avisa a RR.HH. de los empleados que deben desde hace más de un mes. Hay un solo
# aviso por empresa, que cuelga de ella y llega a todos sus admins, así que el
# índice de Notification no admite dos activos para el mismo admin.

class EmployeeDebtNotifications
  EVENT = :employee_debt_overdue

  class << self
    # Un mes cuenta como deuda vieja cuando vence el pago del mes siguiente
    def remind!(date: Date.current)
      groups = overdue(Account.where(owner_type: "Consumer"), date).group_by { it.owner.company }

      groups.each { |company, debts| sync(company, debts, create_on: date) }
      close_resolved(except: groups.keys)
    end

    # Actualiza o cierra el aviso cuando cambia lo que debe un empleado. Con
    # renotify (un rechazo), si el mes ya es deuda vieja, vuelve a crear el aviso cerrado.
    def refresh(account, renotify: false)
      return unless account.owner_type == "Consumer"

      company = account.owner.company
      renotify &&= Date.current > account.due_date.next_month
      return unless renotify || Notification.active.exists?(event: EVENT, notifiable: company)

      accounts = Account.where(owner_type: "Consumer", owner_id: company.consumers.select(:id))
      sync(company, overdue(accounts, Date.current), create_on: nil, renotify:)
    end

    private

    def overdue(scope, date)
      unpaid(scope.where(month: ..(date.beginning_of_month - 2.months)))
        .select { date > it.due_date.next_month }
    end

    # Deudas de empleados: sin pago aprobado ni comprobante en revisión.
    def unpaid(scope)
      scope.pending
           .preload(:payments, owner: :company)
           .select { it.collection_status.in?(%w[pending rejected partial]) }
    end

    def sync(company, debts, create_on:, renotify: false)
      data = description_data(debts)

      company.admins.map(&:user).each do |user|
        active = user.notifications.active.find_by(event: EVENT, notifiable: company)

        if debts.empty?
          active&.close!
        elsif active
          update_description(active, data)
        elsif renotify || (create_on && new_notice_due?(user, company, debts, create_on))
          Notifier.call(event_key: EVENT, user:, notifiable: company, description_data: data)
        end
      end
    end

    def update_description(notification, data)
      description = I18n.t!("notifications.#{EVENT}.description", **data)
      notification.update!(description:) unless notification.description == description
    end

    def description_data(debts)
      debtors = debts.map(&:owner).uniq

      { count: debtors.size, amount: Account.format_amount(debtors.sum(&:total_debt)) }
    end

    # Un período se vuelve deuda vieja el día después de due_date.next_month: si
    # el último aviso es de ese día o anterior, ese período no estaba en el aviso.
    def new_notice_due?(user, company, debts, date)
      last = user.notifications.where(event: EVENT, notifiable: company).maximum(:created_at)
      return true if last.nil? || last.to_date <= date - 1.month

      last.to_date <= debts.map(&:due_date).max.next_month
    end

    # También cierra los avisos de cuando colgaban de la cuenta de la empresa.
    def close_resolved(except:)
      Notification.active
                  .where(event: EVENT)
                  .where.not(notifiable_type: "Company", notifiable_id: except.map(&:id))
                  .find_each(&:close!)
    end
  end
end
