# frozen_string_literal: true

class CreateBenefitRules < ActiveRecord::Migration[8.1]
  def change
    create_table :benefit_rules do |t|
      t.integer :limit
      t.date :deadline_date
      t.integer :deadline_days
      t.integer :min_years
      t.decimal :max_price, precision: 10, scale: 2
      t.date :effective_from
      t.string :type
      t.references :benefit_configuration, null: false, foreign_key: true

      t.timestamps
    end
  end
end
