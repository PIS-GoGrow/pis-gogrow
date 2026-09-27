# frozen_string_literal: true

class AddUniqueActiveIndexToBenefits < ActiveRecord::Migration[8.1]
  def change
    add_index :benefits, [:consumer_id, :benefit_configuration_id],
      unique: true,
      where: "status = 0",
      name: "index_benefits_unique_active_per_consumer_config"
  end
end
