# frozen_string_literal: true

class CreateSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :schedules do |t|
      t.date :date
      t.integer :amount
      t.references :menu, null: false, foreign_key: true

      t.timestamps
    end
  end
end
