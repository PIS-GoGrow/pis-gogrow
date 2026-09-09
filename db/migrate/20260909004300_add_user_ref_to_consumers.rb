# frozen_string_literal: true

class AddUserRefToConsumers < ActiveRecord::Migration[8.1]
  def change
    add_reference :consumers, :user, null: false, foreign_key: true
  end
end
