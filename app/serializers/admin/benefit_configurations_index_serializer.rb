# frozen_string_literal: true

class Admin::BenefitConfigurationsIndexSerializer < ApplicationSerializer
  has_many :benefit_configurations, resource: BenefitConfigurationSerializer

  typelize pending_base_subsidy: "BenefitConfiguration | null"
  one :pending_base_subsidy, resource: BenefitConfigurationSerializer
  typelize base_subsidy: "BenefitConfiguration | null"
  one :base_subsidy, resource: BenefitConfigurationSerializer
end
