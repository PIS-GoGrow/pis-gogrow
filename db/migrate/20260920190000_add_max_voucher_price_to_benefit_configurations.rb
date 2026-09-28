# frozen_string_literal: true

class AddMaxVoucherPriceToBenefitConfigurations < ActiveRecord::Migration[8.1]
  def change
    add_column :benefit_configurations, :max_voucher_price, :decimal, precision: 10, scale: 2, null: false
  end
end
