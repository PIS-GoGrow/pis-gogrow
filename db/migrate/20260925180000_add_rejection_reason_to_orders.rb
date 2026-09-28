# frozen_string_literal: true

class AddRejectionReasonToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :rejection_reason, :integer
    add_column :orders, :rejection_details, :string
  end
end
