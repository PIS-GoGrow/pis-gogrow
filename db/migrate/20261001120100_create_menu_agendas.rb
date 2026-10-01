# frozen_string_literal: true

class CreateMenuAgendas < ActiveRecord::Migration[8.1]
  def change
    create_table :menu_agendas do |t|
      t.references :menu, null: false, foreign_key: true
      t.integer :weekdays, array: true, null: false, default: []
      t.date :starts_on, null: false
      t.date :ends_on
      t.integer :amount, null: false

      t.timestamps
    end
  end
end
