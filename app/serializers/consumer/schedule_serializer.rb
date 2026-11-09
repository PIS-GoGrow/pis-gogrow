# frozen_string_literal: true

class Consumer::ScheduleSerializer < ApplicationSerializer
  typelize_from Schedule

  attributes :id, :date, :available

  has_one :menu, serializer: Consumer::MenuWithProviderSerializer
end
