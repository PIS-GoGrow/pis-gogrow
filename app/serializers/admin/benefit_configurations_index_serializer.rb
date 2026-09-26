# frozen_string_literal: true

class Admin::BenefitConfigurationsIndexSerializer < ApplicationSerializer
  has_many :benefit_configurations, resource: BenefitConfigurationSerializer

  typelize current_benefit_configuration: "BenefitConfiguration | null"
  one :current_benefit_configuration, resource: BenefitConfigurationSerializer
end
