# frozen_string_literal: true

class CreateBenefits < ActiveRecord::Migration[8.1]
  def change
    create_table :benefits do |t|
      t.integer :amount
      t.string :description
      t.integer :percentage
      t.date :due_date
      t.references :consumer, null: false, foreign_key: true

      t.timestamps
    end
  end
end
