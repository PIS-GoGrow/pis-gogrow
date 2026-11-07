# frozen_string_literal: true

class BackfillBaseSubsidyConsumerAssignments < ActiveRecord::Migration[8.1]
  def up
    Company.find_each do |company|
      benefit_configuration = BenefitConfiguration.base_subsidy_for(company)
      next unless benefit_configuration
      next if benefit_configuration.deactivated_at?

      company.consumers.find_each do |consumer|
        benefit_configuration.consumer_benefit_configurations.find_or_create_by!(consumer:)
      end

      benefit_configuration.apply_to_all_consumers
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
