# frozen_string_literal: true

class AddDeliveryMethodToOrders < ActiveRecord::Migration[8.1]
  def up
    add_column :orders, :delivery_method, :integer

    execute <<~SQL
      UPDATE orders SET delivery_method = CASE
        WHEN orders.address IS NULL OR btrim(orders.address) = '' THEN 0
        WHEN companies.address IS NOT NULL AND orders.address = companies.address THEN 0
        ELSE 1 END
      FROM consumers, companies
      WHERE consumers.id = orders.consumer_id AND companies.id = consumers.company_id
    SQL

    change_column_null :orders, :delivery_method, false

    add_check_constraint :orders,
                         "delivery_method <> 1 OR (address IS NOT NULL AND btrim(address) <> '')",
                         name: "orders_home_delivery_requires_address"
  end

  def down
    remove_check_constraint :orders, name: "orders_home_delivery_requires_address"
    remove_column :orders, :delivery_method
  end
end
