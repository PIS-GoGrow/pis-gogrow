# frozen_string_literal: true

class CreateFavorites < ActiveRecord::Migration[8.1]
  def change
    create_table :favorites do |t|
      t.references :consumer, null: false, foreign_key: true
      t.references :favoritable, polymorphic: true, null: false
      t.timestamps
    end

    add_index :favorites, [ :consumer_id, :favoritable_type, :favoritable_id ], unique: true, name: "index_favorites_on_consumer_and_favoritable"
  end
end
