# frozen_string_literal: true

class AddHomeDeliveryToProviders < ActiveRecord::Migration[8.1]
  def change
    add_column :providers, :home_delivery, :boolean, default: true, null: false
  end
end
