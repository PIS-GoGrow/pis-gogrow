# frozen_string_literal: true

class AddUserRefToAdmins < ActiveRecord::Migration[8.1]
  def change
    add_reference :admins, :user, null: false, foreign_key: true
  end
end
