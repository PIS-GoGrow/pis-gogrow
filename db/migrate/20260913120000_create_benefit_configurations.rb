# frozen_string_literal: true

class CreateBenefitConfigurations < ActiveRecord::Migration[8.1]
  def change
    create_table :benefit_configurations do |t|
      t.references :company, null: false, foreign_key: true
      t.integer :subsidy_percentage, null: false
      t.integer :monthly_voucher_limit, null: false
      t.date :effective_from, null: false
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :benefit_configurations, [ :company_id, :effective_from ], unique: true
  end
end
