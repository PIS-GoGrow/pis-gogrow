# frozen_string_literal: true

class CreateBenefitConfigurationChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :benefit_configuration_changes do |t|
      t.references :benefit_configuration, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :action, null: false
      t.jsonb :details, null: false, default: {}

      t.timestamps
    end
  end
end
