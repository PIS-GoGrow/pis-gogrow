# frozen_string_literal: true

class AddDeactivatedAtToBenefitConfigurations < ActiveRecord::Migration[8.1]
  def change
    add_column :benefit_configurations, :deactivated_at, :datetime
  end
end
