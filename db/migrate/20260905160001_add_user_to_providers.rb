# frozen_string_literal: true

class AddUserToProviders < ActiveRecord::Migration[8.1]
  def change
    add_reference :providers, :user, foreign_key: { on_delete: :nullify }, index: { unique: true }
  end
end
