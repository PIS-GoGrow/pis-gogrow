# frozen_string_literal: true

module Menus
  module Import
    # La planilla tal como la muestra la pantalla: una tarjeta por fila con todo
    # lo que hace falta para revisarla sin volver al servidor. Lo que el
    # proveedor decide ahí vuelve en el segundo paso, así la planilla no queda
    # guardada entre uno y otro. Ver docs/importar-menu.md.
    class Preview
      def self.call(...) = new(...).call

      def initialize(plan:, filename: nil)
        @plan = plan
        @filename = filename
      end

      def call
        {
          # Cambia con cada planilla subida: es lo que le avisa a la pantalla que
          # tiene que empezar de nuevo y descartar lo que venía revisando.
          id: SecureRandom.hex(8),
          filename: @filename,
          error: @plan.error,
          entries: @plan.entries.map { entry(it) }
        }
      end

      private

      def entry(entry)
        {
          number: entry.number,
          name: entry.name,
          description: entry.description,
          price: entry.price&.to_f,
          option_groups: entry.option_groups,
          errors: entry.errors
        }
      end
    end
  end
end
