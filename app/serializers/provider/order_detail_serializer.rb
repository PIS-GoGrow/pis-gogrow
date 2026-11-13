# frozen_string_literal: true

# El detalle agrega lo que el proveedor necesita para decidir y preparar: con
# quién es el pedido, qué lleva el plato y cuánto cupo queda del día.
class Provider::OrderDetailSerializer < Provider::OrderSerializer
  typelize :string
  attribute :consumer_email do |order|
    order.consumer.user.email
  end

  typelize :string, nullable: true
  attribute :consumer_phone do |order|
    order.consumer.user.phone
  end

  typelize :string
  attribute :created_on do |order|
    order.created_at.to_date.iso8601
  end

  # El snapshot conserva el id de cada grupo para poder cruzarlo con la elección
  # del empleado en selected_options. Los pedidos hechos antes de que existiera
  # el snapshot no lo tienen, y ahí se recurre al grupo real del plato.
  typelize "{ id: number; name: string; options: string[]; limit: number }[]"
  attribute :menu_option_groups do |order|
    groups = order.menu_option_groups.presence || order.schedule&.menu&.option_groups_snapshot || []

    groups.map do |g|
      group = g.respond_to?(:[]) && !g.is_a?(MenuOptionGroup) ? g : g.attributes
      { id: group["id"], name: group["name"], options: group["options"], limit: group["limit"] }
    end
  end

  typelize "Array<{ group_id: number; name: string; values: string[] }>"
  attribute :selected_options do |order|
    order.selected_options
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
