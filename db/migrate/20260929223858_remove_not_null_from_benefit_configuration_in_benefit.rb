# frozen_string_literal: true

class RemoveNotNullFromBenefitConfigurationInBenefit < ActiveRecord::Migration[8.1]
  def change
    change_column :benefits, :benefit_configuration_id, :bigint, null: true
  end
end
