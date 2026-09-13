# frozen_string_literal: true

class Consumer::MenuSerializer < ApplicationSerializer
  typelize_from Menu

  attributes :id, :name, :description

  typelize :string
  attribute :price do |menu|
    menu.price.to_s
  end

  typelize :string?
  attribute :provider_name do |menu|
    menu.provider.user&.name
  end

  has_many :schedules, resource: ScheduleSerializer
end
