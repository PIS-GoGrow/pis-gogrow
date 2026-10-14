# frozen_string_literal: true

class Menus::MissingPublicationDetector
  def self.call(date: Date.current)
    return Provider.none unless date.on_weekday?

    published_provider_ids = Schedule.on_active_menus.where(date:).select("menus.provider_id")

    # TODO(integración IBP-087): excluir proveedores cerrados cuando los cierres programados lleguen a develop.
    Provider.where.not(id: published_provider_ids)
  end
end
