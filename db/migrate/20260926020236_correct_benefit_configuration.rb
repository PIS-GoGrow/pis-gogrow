# frozen_string_literal: true

class CorrectBenefitConfiguration < ActiveRecord::Migration[8.1]
  def change
    add_column :benefit_configurations, :name, :string
    add_column :benefit_configurations, :applies_to_all, :boolean, default: false

    remove_column :benefit_configurations, :monthly_voucher_limit, :integer
    remove_column :benefit_configurations, :effective_from, :date
    remove_column :benefit_configurations, :max_voucher_price, :decimal
  end
end
