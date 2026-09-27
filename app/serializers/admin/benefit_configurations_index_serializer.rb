# frozen_string_literal: true

class Admin::BenefitConfigurationsIndexSerializer < ApplicationSerializer
  has_many :benefit_configurations, resource: BenefitConfigurationSerializer

  typelize current_benefit_configuration: "BenefitConfiguration | null"
  one :pending_base_subsidy, resource: BenefitConfigurationSerializer
  one :base_subsidy, resource: BenefitConfigurationSerializer
end
