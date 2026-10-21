# frozen_string_literal: true

class AddMaxPriceToBenefits < ActiveRecord::Migration[8.1]
  def change
    add_column :benefits, :max_price, :decimal, precision: 10, scale: 2, if_not_exists: true
  end
end
