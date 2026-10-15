# frozen_string_literal: true

class Menus::MissingPublicationDetector
  def self.call(date: Date.current)
    return Provider.none unless date.on_weekday?

    published_provider_ids = Schedule.on_active_menus.where(date:).select("menus.provider_id")

    unpublished_providers = Provider.where.not(id: published_provider_ids)
    closed_provider_ids = unpublished_providers.includes(:closures).select { it.closed_on?(date) }.map(&:id)

    unpublished_providers.where.not(id: closed_provider_ids)
  end
end
