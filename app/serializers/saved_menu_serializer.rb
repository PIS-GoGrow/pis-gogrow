# frozen_string_literal: true

class SavedMenuSerializer < ApplicationSerializer
  typelize_from Menu

  attributes :id, :name, :description, :price

  # Pedidos de hoy en adelante que se ven afectados si el plato se elimina.
  typelize :number
  attribute :confirmed_orders do |menu|
    menu.upcoming_orders_count(:confirmed)
  end

  typelize :number
  attribute :pending_orders do |menu|
    menu.upcoming_orders_count(:pending)
  end

  # Días en los que el plato se repite según su agenda vigente (1 = lunes ... 5 = viernes).
  typelize "number[]"
  attribute :weekdays do |menu|
    menu.current_agenda&.weekdays || []
  end
end
