# frozen_string_literal: true

class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.string :name
      t.string :address

      t.timestamps
    end
  end
end
