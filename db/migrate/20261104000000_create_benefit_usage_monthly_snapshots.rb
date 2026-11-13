# frozen_string_literal: true

class CreateBenefitUsageMonthlySnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :benefit_usage_monthly_snapshots do |t|
      t.references :company, null: false, foreign_key: true
      t.date :month, null: false
      t.integer :status, null: false, default: 0
      t.integer :calculation_version, null: false, default: 1
      t.datetime :captured_at, null: false
      t.datetime :closed_at
      t.boolean :fictional, null: false, default: false
      t.jsonb :unavailable_reasons, null: false, default: {}

      t.integer :employees
      t.integer :eligible_employees
      t.integer :unknown_eligibility_employees
      t.integer :employees_with_confirmed_orders
      t.integer :eligible_with_confirmed_orders
      t.integer :eligible_without_orders
      t.integer :monthly_quota_meals
      t.integer :monthly_subsidized_meals
      t.integer :monthly_pending_reserved_meals
      t.integer :monthly_available_meals
      t.integer :monthly_unused_closed_meals
      t.integer :confirmed_orders
      t.integer :confirmed_meals
      t.integer :confirmed_meals_without_monthly_subsidy
      t.integer :pending_orders
      t.integer :pending_meals
      t.decimal :company_subsidy_amount, precision: 14, scale: 2

      t.timestamps
    end

    add_index :benefit_usage_monthly_snapshots, [ :company_id, :month ], unique: true
    add_check_constraint :benefit_usage_monthly_snapshots, "month = date_trunc('month', month)::date", name: "benefit_usage_snapshot_first_day"
    add_check_constraint :benefit_usage_monthly_snapshots, "status IN (0, 1, 2)", name: "benefit_usage_snapshot_status"
    add_check_constraint :benefit_usage_monthly_snapshots, "calculation_version > 0", name: "benefit_usage_snapshot_version"
    add_check_constraint :benefit_usage_monthly_snapshots, "(status = 1) = (closed_at IS NOT NULL)", name: "benefit_usage_snapshot_closed_at"
    %i[
      employees eligible_employees unknown_eligibility_employees employees_with_confirmed_orders
      eligible_with_confirmed_orders eligible_without_orders monthly_quota_meals monthly_subsidized_meals
      monthly_pending_reserved_meals monthly_available_meals monthly_unused_closed_meals confirmed_orders
      confirmed_meals confirmed_meals_without_monthly_subsidy pending_orders pending_meals company_subsidy_amount
    ].each do |metric|
      add_check_constraint :benefit_usage_monthly_snapshots, "#{metric} >= 0", name: "bus_#{metric}_nonnegative"
    end
  end
end
