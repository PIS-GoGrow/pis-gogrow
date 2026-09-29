# frozen_string_literal: true

class CreateConsumerBenefitConfigurations < ActiveRecord::Migration[8.1]
  def change
    create_table :consumer_benefit_configurations do |t|
      t.references :benefit_configuration, null: false, foreign_key: true
      t.references :consumer, null: false, foreign_key: true

      t.timestamps
    end
  end
end
