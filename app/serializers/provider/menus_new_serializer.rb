# frozen_string_literal: true

class Provider::MenusNewSerializer < ApplicationSerializer
  has_many :saved_menus, resource: SavedMenuSerializer

  typelize today: :string, maximum_publish_date: :string, default_date: [ :string, nullable: true ],
           published: "{ date: string; menu_id: number }[]"
  attributes :today, :maximum_publish_date, :default_date, :published
end
