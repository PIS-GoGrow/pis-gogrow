# frozen_string_literal: true

class BenefitAssignationJob < ApplicationJob
  queue_as :default

  def perform(*args)
    benefit_configurations = BenefitConfiguration.includes :consumers, :benefit_rules

    benefit_configurations.find_each do |config|
      config.apply_to_all_consumers
    rescue => e
      Rails.error.report(e, context: { benefit_configuration_id: config.id }, handled: true)
    end
  end
end
