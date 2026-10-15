# frozen_string_literal: true

class Settings::NotificationsIndexSerializer < ApplicationSerializer
  attributes :subscribed_keys
  typelize subscribed_keys: "[string]"

  has_many :notification_configurations, serializer: Settings::NotificationConfigurationSerializer
end
