# frozen_string_literal: true

class EmployeeOrderRemindersJob < ApplicationJob
  queue_as :default

  def perform(date: Date.current, now: Time.current)
    OrderReminders::Generate.call(date:, now:)
  end
end
