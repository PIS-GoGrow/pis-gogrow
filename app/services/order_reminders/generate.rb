# frozen_string_literal: true

module OrderReminders
  class Generate
    EVENT = :order_deadline_reminder
    REMINDER_BEFORE = 1.hour
    ACTIVE_ORDER_STATUSES = %w[pending confirmed].freeze

    def self.call(date: Date.current, now: Time.current)
      new(date:, now:).call
    end

    def initialize(date:, now:)
      @date = date.to_date
      @now = now.in_time_zone
    end

    def call
      deadline_at = first_deadline_at
      return unless deadline_at

      # Decision: Se envia la notificacion 1 hora antes de la primera hora de cierre.
      reminder_at = deadline_at - REMINDER_BEFORE
      return if now < reminder_at || now >= deadline_at

      Consumer.includes(:user).find_each do |consumer|
        notify_if_eligible(consumer)
      end
    end

    private

    attr_reader :date, :now

    def first_deadline_at
      deadline =
        providers_with_published_menu
          .filter_map do |provider|
            next if provider.closed_on?(date)

            provider.order_deadline
          end
          .min

      return unless deadline

      Time.zone.local(
        date.year,
        date.month,
        date.day,
        deadline.hour,
        deadline.min,
        deadline.sec
      )
    end

    def providers_with_published_menu
      @providers_with_published_menu ||=
        Provider
          .joins(menus: :schedules)
          .where(schedules: { date: })
          .where(menus: { archived_at: nil })
          .where.not(order_deadline: nil)
          .includes(:closures)
          .distinct
    end

    def notify_if_eligible(consumer)
      return if ordered_for_date?(consumer)

      consumer.with_lock do
        return if ordered_for_date?(consumer)
        return if already_notified?(consumer)

        close_previous_active_reminders(consumer)

        notification = Notifier.call(
          event_key: EVENT,
          user: consumer.user,
          notifiable: consumer
        )

        Rails.logger.error(
          "[OrderReminders::Generate] No se pudo crear #{EVENT} para Consumer##{consumer.id}"
        ) unless notification
      end
    end

    # Funcion auxiliar para que, si el consumidor no cierra un recordatorio de una fecha pasada, en el dia actual
    # se cierra automaticamente y se crea una nueva:
    def close_previous_active_reminders(consumer)
      consumer.user.notifications
              .active
              .where(event: EVENT, notifiable: consumer)
              .where(created_at: ...date.in_time_zone.beginning_of_day)
              .find_each(&:close!)
    end

    def ordered_for_date?(consumer)
      consumer.orders
              .joins(:schedule)
              .where(
                schedules: { date: },
                status: ACTIVE_ORDER_STATUSES
              )
              .exists?
    end

    def already_notified?(consumer)
      consumer.user.notifications.where(
        event: EVENT,
        notifiable: consumer,
        created_at: date.in_time_zone.all_day
      ).exists?
    end
  end
end
