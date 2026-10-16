# frozen_string_literal: true

class AddHistoricalContextToOrders < ActiveRecord::Migration[8.1]
  def up
    add_reference :orders, :provider, foreign_key: { on_delete: :nullify }
    add_column :orders, :provider_name, :string
    add_column :orders, :delivery_date, :date
    add_column :orders, :rejected_at, :datetime
    add_reference :orders, :rejected_by, foreign_key: { to_table: :users, on_delete: :nullify }

    execute <<~SQL
      UPDATE orders
      SET provider_id = menus.provider_id,
          provider_name = users.name,
          delivery_date = schedules.date
      FROM schedules
      JOIN menus ON menus.id = schedules.menu_id
      JOIN providers ON providers.id = menus.provider_id
      LEFT JOIN users ON users.id = providers.user_id
      WHERE schedules.id = orders.schedule_id
    SQL
  end

  def down
    remove_reference :orders, :rejected_by, foreign_key: true
    remove_column :orders, :rejected_at
    remove_column :orders, :delivery_date
    remove_column :orders, :provider_name
    remove_reference :orders, :provider, foreign_key: true
  end
end
