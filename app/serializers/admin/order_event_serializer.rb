# frozen_string_literal: true

class Admin::OrderEventSerializer < ApplicationSerializer
  typelize_from OrderEvent

  attributes :id, :order_id, :action, :role

  # Formateada en el servidor: el SSR corre en UTC y el cliente no.
  typelize :string
  attribute :occurred_at do |event|
    I18n.l(event.created_at, format: "%d/%m/%Y %H:%M:%S")
  end

  typelize :string?
  attribute :actor_name do |event|
    event.actor_name || event.user&.name
  end

  typelize :string?
  attribute :consumer_name do |event|
    event.order&.consumer&.user&.name
  end

  typelize :string?
  attribute :dish do |event|
    event.order&.menu_name
  end

  typelize "Array<{ field: 'status' | 'amount' | 'price' | 'discounted_price' | 'delivery_method' | 'address' | 'notes' | 'selected_options' | 'rejection_reason' | 'rejection_details'; before: string | null; after: string | null }>"
  attribute :changes do |event|
    event.changeset.map do |field, (before, after)|
      before = nil if event.created?
      { field:, before: format_value(field, before), after: format_value(field, after) }
    end
  end

  private

  def format_value(field, value)
    return if value.nil?

    case field
    when "status" then I18n.t("pages.orders.statuses.#{value}")
    when "delivery_method" then I18n.t("pages.orders.delivery_methods.#{value}")
    when "rejection_reason" then I18n.t("pages.provider_orders.rejection_reasons.#{value}")
    when "price", "discounted_price" then Account.format_amount(value)
    when "selected_options" then value.flat_map { it["values"] }.join(", ")
    else value.to_s
    end
  end
end
