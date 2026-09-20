# frozen_string_literal: true

class BenefitConfigurationSerializer < ApplicationSerializer
  typelize_from BenefitConfiguration

  attributes :id, :subsidy_percentage, :monthly_voucher_limit, :max_voucher_price, :effective_from, :created_at

  typelize :string
  attribute :created_by_name do |benefit_configuration|
    benefit_configuration.created_by.name
  end
end
