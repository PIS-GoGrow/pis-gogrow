# frozen_string_literal: true

# El detalle agrega lo que el proveedor necesita para decidir y preparar: con
# quién es el pedido, qué lleva el plato y cuánto cupo queda del día.
class Provider::OrderDetailSerializer < Provider::OrderSerializer
  typelize :string, nullable: true
  attribute :date do |order|
    order.schedule&.date&.iso8601
  end

  typelize_from Order
  attributes :delivery_method

  typelize :string, nullable: true
  attribute :consumer_company do |order|
    order.consumer.company&.name
  end

  typelize :string
  attribute :consumer_email do |order|
    order.consumer.user.email
  end

  typelize :string, nullable: true
  attribute :menu_description do |order|
    order.menu_description
  end

  typelize "{ id: number; name: string; options: string[]; limit: number }[]"
  attribute :menu_option_groups do |order|
    order.menu_option_groups.map.with_index do |g, index|
      { id: index, name: g["name"], options: g["options"], limit: g["limit"] }
    end
  end

  typelize "Array<{ group_id: number; name: string; values: string[] }>"
  attribute :selected_options do |order|
    order.selected_options
  end

  typelize :number, nullable: true
  attribute :discounted_price do |order|
    order.discounted_price&.to_f
  end

  typelize :number, nullable: true
  attribute :subsidy do |order|
    order.subsidy&.to_f
  end

  # Cupo del día del plato: cuánto se publicó y cuánto queda sin comprometer.
  typelize :number, nullable: true
  attribute :schedule_amount do |order|
    order.schedule&.amount
  end

  typelize :number, nullable: true
  attribute :remaining_amount do |order|
    order.schedule&.remaining_amount
  end

  typelize :string, nullable: true
  attribute :rejection_reason do |order|
    order.rejection_reason
  end

  typelize :string, nullable: true
  attribute :rejection_details do |order|
    order.rejection_details
  end
end
