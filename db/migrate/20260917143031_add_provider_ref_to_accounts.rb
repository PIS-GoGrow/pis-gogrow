# frozen_string_literal: true

class AddProviderRefToAccounts < ActiveRecord::Migration[8.1]
  def up
    add_reference :accounts, :provider, null: true, foreign_key: true

    execute <<~SQL
      UPDATE accounts
      SET provider_id = subquery.provider_id
      FROM (
        SELECT order_accounts.account_id, menus.provider_id
        FROM order_accounts
        INNER JOIN orders ON orders.id = order_accounts.order_id
        INNER JOIN schedules ON schedules.id = orders.schedule_id
        INNER JOIN menus ON menus.id = schedules.menu_id
      ) AS subquery
      WHERE accounts.id = subquery.account_id AND accounts.provider_id IS NULL;
    SQL

    execute <<~SQL
      UPDATE accounts
      SET provider_id = (SELECT id FROM providers ORDER BY id LIMIT 1)
      WHERE provider_id IS NULL;
    SQL

    execute <<~SQL
      DELETE FROM accounts WHERE provider_id IS NULL;
    SQL

    change_column_null :accounts, :provider_id, false
  end

  def down
    remove_reference :accounts, :provider
  end
end
