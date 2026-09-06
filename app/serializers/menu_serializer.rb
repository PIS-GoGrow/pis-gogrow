# frozen_string_literal: true

class MenuSerializer < ApplicationSerializer
  typelize_from Menu

  attributes :id, :name, :description, :price, :created_at, :updated_at
end
