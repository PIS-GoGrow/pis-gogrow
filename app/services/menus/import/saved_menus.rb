# frozen_string_literal: true

module Menus
  module Import
    # Los platos que el proveedor ya tiene guardados, como los necesita la vista
    # previa: para cruzarlos por nombre con las filas de la planilla, para
    # avisar antes de tocar pedidos ya confirmados y para devolverle al plato su
    # agenda si el proveedor la actualiza sin tocarla.
    # Ver docs/importar-menu.md.
    class SavedMenus
      NO_AGENDA = { mode: "none", weekdays: [], date: nil, starts_on: nil, ends_on: nil, amount: nil }.freeze

      def self.call(...) = new(...).call

      def initialize(provider:)
        @provider = provider
      end

      def call
        menus.map do |menu|
          {
            id: menu.id,
            name: menu.name.to_s,
            confirmed_orders: confirmed_orders.fetch(menu.id, 0),
            agenda: agenda(menu.current_agenda)
          }
        end
      end

      private

      def menus = @menus ||= @provider.menus.saved.includes(:agendas).order(:id).to_a

      # Los pedidos confirmados que faltan entregar, de cada plato guardado y de
      # sus variantes, en una sola consulta: la tarjeta los muestra para todos
      # los platos de la planilla a la vez.
      def confirmed_orders
        @confirmed_orders ||= Order
          .where(status: :confirmed)
          .joins(schedule: :menu)
          .where(menus: { provider_id: @provider.id }, schedules: { date: Date.current.. })
          .group(Arel.sql("COALESCE(menus.base_menu_id, menus.id)"))
          .count
      end

      # La agenda que el plato ya tiene. Va en la vista previa porque
      # actualizarlo sin agenda se la sacaría: si el proveedor no la toca, se
      # devuelve tal cual estaba.
      def agenda(agenda)
        return NO_AGENDA if agenda.nil?

        {
          mode: agenda.ends_on ? "range" : "weekly",
          weekdays: agenda.weekdays,
          date: nil,
          starts_on: [ agenda.starts_on, Date.current ].max.iso8601,
          ends_on: agenda.ends_on&.iso8601,
          amount: agenda.amount
        }
      end
    end
  end
end
