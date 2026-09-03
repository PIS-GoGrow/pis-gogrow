# frozen_string_literal: true

class CreateAdmins < ActiveRecord::Migration[8.1]
  def change
    create_table :admins do |t|
      t.string :email
      t.string :username
      t.references :company, null: false, foreign_key: true

      t.timestamps
    end
    add_index :admins, :email, unique: true
  end
end
