# frozen_string_literal: true

class Notifier
  def self.call(key:, configuration_key:, user:, requires_action:, title_data: {}, description_data: {})
    configuration = NotificationConfiguration.find_by!(key: configuration_key)

    Notification.create!(
      notification_configuration: configuration,
      user:,
      requires_action:,
      title: I18n.t!("notifications.#{key}.title", **title_data),
      description: I18n.t!("notifications.#{key}.description", **description_data)
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[Notifier] #{e.class}: #{e.message}")
    nil
  end
end
