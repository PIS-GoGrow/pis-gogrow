# frozen_string_literal: true

module Menus
  module Import
    # Guarda el plan, todo o nada. Cada fila pasa por el mismo servicio que el
    # formulario —Menus::Create o Menus::Update—, así la importación hereda sus
    # validaciones, el cuidado de lo que ya está publicado y la programación.
    class Save
      class Failed < StandardError; end

      # Mensajes por número de fila, para lo que recién se ve al guardar: la
      # vista previa los muestra en el mismo lugar que los suyos.
      attr_reader :errors

      def initialize(provider:, plan:, by: nil)
        @provider = provider
        @plan = plan
        @by = by
        @errors = {}
      end

      def call
        return false unless @plan.valid?

        Menu.transaction { @plan.entries.each { save(it) } }

        true
      rescue Failed
        false
      end

      private

      def save(entry)
        service = entry.menu ? update(entry) : create(entry)
        return if service.call

        @errors[entry.number] = service.errors.full_messages
        raise Failed
      end

      def create(entry)
        Menus::Create.new(provider: @provider, attributes: entry.row.attributes, agenda: entry.row.agenda)
      end

      def update(entry)
        Menus::Update.new(
          menu: entry.menu,
          attributes: entry.row.attributes.merge(option_groups_attributes: groups_for(entry)),
          agenda: entry.row.agenda,
          by: @by
        )
      end

      # Los grupos de la planilla se cruzan por nombre con los que el plato ya
      # tenía: el que existía conserva su id, así los pedidos ya hechos siguen
      # cruzando la elección del empleado con el grupo. El que la planilla no
      # trae se borra.
      def groups_for(entry)
        existing = entry.menu.option_groups.index_by { it.name.to_s.strip.downcase }
        groups = entry.row.option_groups.map do |group|
          id = existing.delete(group[:name].downcase)&.id
          id ? group.merge(id:) : group
        end

        groups + existing.values.map { { id: it.id, _destroy: true } }
      end
    end
  end
end
