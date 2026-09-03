# frozen_string_literal: true

class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.string :description
      t.integer :rating
      t.references :menu, null: false, foreign_key: true

      t.timestamps
    end
  end
end
