# frozen_string_literal: true

class CreateOtpCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :otp_codes do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.integer :purpose, null: false
      t.string :nonce, null: false
      t.datetime :expires_at, null: false
      t.integer :attempts, null: false, default: 0
      t.datetime :sent_at, null: false

      t.timestamps
    end

    add_index :otp_codes, [ :user_id, :purpose ], unique: true
  end
end
