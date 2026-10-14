# frozen_string_literal: true

class Settings::NotificationConfigurationSerializer < ApplicationSerializer
  attributes :id, :key, :title, :description

  typelize id: :number
  typelize key: :string
  typelize title: :string
  typelize description: :string
end
