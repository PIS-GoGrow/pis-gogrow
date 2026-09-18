# frozen_string_literal: true

class Consumer::ScheduleSerializer < ApplicationSerializer
  typelize_from Schedule

  attributes :id, :date, :amount

  has_one :menu, serializer: Consumer::MenuWithProviderSerializer
end
