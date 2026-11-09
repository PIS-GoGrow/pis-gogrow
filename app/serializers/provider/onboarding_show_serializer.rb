# frozen_string_literal: true

class Provider::OnboardingShowSerializer < ApplicationSerializer
  has_one :provider, serializer: Provider::OnboardingProviderSerializer
  has_many :notification_configurations, serializer: Settings::NotificationConfigurationSerializer
  has_many :closures, serializer: ProviderClosureSerializer

  typelize step: :string
  typelize subscribed_keys: "[string]"
  typelize today: :string
  typelize order_deadline_passed_today: :boolean
  attributes :step, :subscribed_keys, :today, :order_deadline_passed_today
end
