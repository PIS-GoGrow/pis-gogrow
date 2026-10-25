# frozen_string_literal: true

class Provider::OnboardingProviderSerializer < ApplicationSerializer
  typelize_from Provider

  attributes :bank_name, :bank_account_type, :bank_account_number, :bank_account_holder, :tax_id, :home_delivery

  typelize :string?
  attribute :order_deadline do |provider|
    provider.order_deadline&.strftime("%H:%M")
  end

  typelize deliveries_configured: :boolean
  attribute :deliveries_configured do |provider|
    provider.deliveries_configured_at.present?
  end
end
