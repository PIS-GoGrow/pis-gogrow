# frozen_string_literal: true

module Menus
  module Import
    # Guarda la lista que el proveedor revisó en la vista previa. Cada entrada
    # llega con la acción que eligió —crear el plato o actualizar uno guardado—,
    # así que acá no se decide nada: se escribe.
    #
    # Cada fila pasa por el mismo servicio que el formulario, Menus::Create o
    # Menus::Update, de modo que la importación hereda sus validaciones, el
    # cuidado de lo que ya está publicado y la programación. Todo va en una
    # transacción: si una fila falla recién al guardar, no queda media
    # importación hecha y el error vuelve a la tarjeta que lo produjo.
    # Ver docs/importar-menu.md.
    class Save
      class Failed < StandardError; end

      # Mensajes por tarjeta de la vista previa. La identifica la clave que ella
      # misma manda: después de quitar, duplicar y editar, sus tarjetas ya no
      # tienen por qué coincidir con las filas del archivo.
      attr_reader :errors

      def initialize(provider:, entries:, by: nil)
        @provider = provider
        @entries = Array(entries)
        @by = by
        @errors = {}
      end

      def call
        return false if @entries.empty?

        Menu.transaction { @entries.each { save(it) } }

        true
      rescue Failed
        false
      end

      def count = @entries.size

      private

      def save(entry)
        service = update?(entry) ? update(entry) : create(entry)
        return if service.call

        @errors[entry[:key]] = service.errors.full_messages
        raise Failed
      end

      def update?(entry) = entry[:action].to_s == "update"

      def create(entry)
        Menus::Create.new(provider: @provider, attributes: attributes(entry), agenda: agenda(entry))
      end

      def update(entry)
        menu = saved_menu(entry)

        Menus::Update.new(
          menu: menu,
          attributes: attributes(entry).merge(option_groups_attributes: groups_for(menu, entry)),
          agenda: agenda(entry),
          confirmed_orders: entry[:confirmed_orders],
          by: @by
        )
      end

      # Siempre dentro de los platos del proveedor: el id llega del navegador.
      def saved_menu(entry) = @provider.menus.saved.find(entry[:menu_id])

      def attributes(entry)
        {
          name: entry[:name],
          description: entry[:description],
          price: entry[:price],
          option_groups_attributes: option_groups(entry)
        }
      end

      def option_groups(entry)
        Array(entry[:option_groups]).map do |group|
          options = Array(group[:options]).map { it.to_s.strip }.reject(&:empty?)

          { name: group[:name].to_s.strip, options: options, required: group[:required], limit: group[:limit] }
        end
      end

      def agenda(entry) = (entry[:agenda] || { mode: "none" }).to_h.symbolize_keys

      # Los grupos que manda la vista previa se cruzan por nombre con los que el
      # plato ya tenía: el que existía conserva su id, así los pedidos ya hechos
      # siguen cruzando la elección del empleado con el grupo. El que la
      # importación no trae se borra.
      def groups_for(menu, entry)
        existing = menu.option_groups.index_by { it.name.to_s.strip.downcase }
        groups = option_groups(entry).map do |group|
          id = existing.delete(group[:name].downcase)&.id
          id ? group.merge(id: id) : group
        end

        groups + existing.values.map { { id: it.id, _destroy: true } }
      end
    end
  end
end
