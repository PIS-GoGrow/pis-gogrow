# frozen_string_literal: true

class Admin::BenefitConfigurationsIndexSerializer < ApplicationSerializer
  has_many :benefit_configurations, resource: BenefitConfigurationSerializer
  has_many :pending_base_subsidies, resource: BenefitConfigurationSerializer

  typelize base_subsidy: "BenefitConfiguration | null"
  one :base_subsidy, resource: BenefitConfigurationSerializer
  
  typelize configurable_month: "string"
  attributes :configurable_month
end
