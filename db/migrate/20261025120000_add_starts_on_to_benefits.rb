# frozen_string_literal: true

class AddStartsOnToBenefits < ActiveRecord::Migration[8.1]
  def change
    add_column :benefits, :starts_on, :date
  end
end
