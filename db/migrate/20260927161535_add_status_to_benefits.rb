# frozen_string_literal: true

class AddStatusToBenefits < ActiveRecord::Migration[8.1]
  def change
    add_column :benefits, :status, :integer
  end
end
