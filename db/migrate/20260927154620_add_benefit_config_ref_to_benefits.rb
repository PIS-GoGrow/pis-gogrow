# frozen_string_literal: true

class AddBenefitConfigRefToBenefits < ActiveRecord::Migration[8.1]
  def change
    add_reference :benefits, :benefit_configuration, null: false, foreign_key: true
  end
end
