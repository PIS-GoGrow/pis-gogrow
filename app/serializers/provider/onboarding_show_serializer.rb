# frozen_string_literal: true

class Provider::OnboardingShowSerializer < ApplicationSerializer
  has_one :provider, serializer: Provider::OnboardingProviderSerializer
  has_many :notification_configurations, serializer: Settings::NotificationConfigurationSerializer

  typelize step: :string
  typelize subscribed_keys: "[string]"
  attributes :step, :subscribed_keys
end
