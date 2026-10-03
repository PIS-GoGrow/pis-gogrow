# frozen_string_literal: true

class AddMenuSnapshotToOrders < ActiveRecord::Migration[8.1]
  def up
    add_column :orders, :menu_name, :string
    add_column :orders, :menu_description, :string
    add_column :orders, :menu_option_groups, :jsonb

    execute <<~SQL
      UPDATE orders
      SET menu_name = menus.name,
          menu_description = menus.description,
          menu_option_groups = COALESCE((
            SELECT jsonb_agg(jsonb_build_object('name', g.name, 'options', to_jsonb(g.options), 'limit', g."limit") ORDER BY g.id)
            FROM menu_option_groups g
            WHERE g.menu_id = menus.id
          ), '[]'::jsonb)
      FROM schedules
      JOIN menus ON menus.id = schedules.menu_id
      WHERE schedules.id = orders.schedule_id
    SQL
  end

  def down
    remove_column :orders, :menu_option_groups
    remove_column :orders, :menu_description
    remove_column :orders, :menu_name
  end
end
