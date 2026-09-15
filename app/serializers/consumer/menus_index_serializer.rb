# frozen_string_literal: true

class Consumer::MenusIndexSerializer < ApplicationSerializer
  attributes :date
  typelize date: :string

  has_many :schedules, serializer: Consumer::ScheduleSerializer
  has_many :providers, serializer: Consumer::ProviderSerializer
end
