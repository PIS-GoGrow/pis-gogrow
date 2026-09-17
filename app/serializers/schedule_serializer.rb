# frozen_string_literal: true

class ScheduleSerializer < ApplicationSerializer
  typelize_from Schedule

  attributes :id, :date, :amount
end
