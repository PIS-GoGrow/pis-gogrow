# frozen_string_literal: true

class ProviderMenuUnpublishedRemindersJob < ApplicationJob
  queue_as :default

  def perform(date: Date.current)
    providers = Menus::MissingPublicationDetector.call(date:)
    Menus::MissingPublicationNotifier.call(providers:, date:)
  end
end
