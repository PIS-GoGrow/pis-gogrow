# frozen_string_literal: true

class MenusGenerateSchedulesJob < ApplicationJob
  def perform
    Menus::AgendaScheduler.call_all
  end
end
