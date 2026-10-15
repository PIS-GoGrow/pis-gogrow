# frozen_string_literal: true

class Menus::MissingPublicationNotifier
  EVENT = :provider_menu_unpublished

  def self.call(providers:, date: Date.current)
    new(providers:, date:).call
  end

  def self.close_for(schedule:)
    return unless schedule.date == Date.current && !schedule.menu.archived?

    provider = schedule.menu.provider
    return unless provider.user

    provider.with_lock do
      Notification.close_by(event: EVENT, notifiable: provider, user: provider.user)
    end
  end

  def self.close_obsolete(date: Date.current)
    Notification.active.where(event: EVENT, created_at: ...date.in_time_zone).find_each do |notification|
      Notification.close_by(event: EVENT, notifiable: notification.notifiable, user: notification.user)
    end
  end

  def self.close_published(date: Date.current)
    Notification.active.where(event: EVENT, notifiable_type: "Provider", created_at: date.in_time_zone.all_day)
      .includes(:notifiable).find_each do |notification|
      provider = notification.notifiable
      next unless provider

      provider.with_lock do
        notification.reload.close! if provider.schedules.on_active_menus.where(date:).exists?
      end
    end
  end

  def initialize(providers:, date:)
    @providers = providers
    @date = date
  end

  def call
    self.class.close_obsolete(date: @date)
    self.class.close_published(date: @date)
    @providers.includes(:user).find_each { notify(it) }
  end

  private

  def notify(provider)
    return unless provider.user

    provider.with_lock do
      return if provider.closed_on?(@date)
      return if provider.schedules.on_active_menus.where(date: @date).exists?
      return if notified_on?(provider)

      Notifier.call(
        event_key: EVENT,
        user: provider.user,
        notifiable: provider,
        description_data: { date: I18n.l(@date) }
      )
    end
  end

  def notified_on?(provider)
    provider.user.notifications.where(
      event: EVENT,
      notifiable: provider,
      created_at: @date.in_time_zone.all_day
    ).exists?
  end
end
