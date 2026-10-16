# frozen_string_literal: true

class EmployeeDebtAlertsJob < ApplicationJob
  queue_as :default

  def perform(date: Date.current)
    EmployeeDebtNotifications.remind!(date:)
  end
end
