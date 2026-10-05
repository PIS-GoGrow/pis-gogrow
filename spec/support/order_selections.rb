# frozen_string_literal: true

module OrderSelections
  # Un pedido de un plato con opciones no es válido sin la elección del empleado.
  # Para los specs que no prueban la personalización alcanza con la primera
  # opción de cada grupo, y devuelve vacío si el plato no ofrece ninguna.
  def selection_for(menu)
    menu.option_groups.map do |group|
      { group_id: group.id, name: group.name, values: [ group.options.first ] }
    end
  end
end

RSpec.configure do |config|
  config.include OrderSelections
end
