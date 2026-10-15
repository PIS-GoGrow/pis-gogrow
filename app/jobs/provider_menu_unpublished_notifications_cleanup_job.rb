# frozen_string_literal: true

class ProviderMenuUnpublishedNotificationsCleanupJob < ApplicationJob
  queue_as :default

  def perform(date: Date.current)
    Menus::MissingPublicationNotifier.close_obsolete(date:)
  end
end
