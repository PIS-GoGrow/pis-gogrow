# frozen_string_literal: true

class OrderSerializer < ApplicationSerializer
  typelize_from Order

  attributes :id, :status, :delivery_method, :amount, :notes, :address

  typelize :string?
  attribute :date do |order|
    order.schedule&.date&.iso8601
  end

  typelize :string?
  attribute :menu_name do |order|
    order.schedule&.menu&.name
  end

  # El proveedor no tiene nombre propio: se identifica por el del usuario dueño.
  typelize :string?
  attribute :provider_name do |order|
    order.schedule&.menu&.provider&.user&.name
  end

  # to_f y no el decimal crudo: Alba serializa BigDecimal como string y el tipo
  # generado diría number. En el cliente solo se formatea, no se opera.
  typelize :number?
  attribute :price do |order|
    order.price&.to_f
  end

  typelize :number?
  attribute :discounted_price do |order|
    order.discounted_price&.to_f
  end

  typelize :number?
  attribute :subsidy do |order|
    order.subsidy&.to_f
  end
end

# == Schema Information
#
# Table name: orders
#
#  id               :bigint           not null, primary key
#  address          :string
#  amount           :integer
#  delivery_method  :integer          not null
#  discounted_price :decimal(10, 2)
#  notes            :string
#  price            :decimal(10, 2)
#  status           :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  consumer_id      :bigint           not null
#  schedule_id      :bigint
#
# Indexes
#
#  index_orders_on_consumer_id  (consumer_id)
#  index_orders_on_schedule_id  (schedule_id)
#
# Foreign Keys
#
#  fk_rails_...  (consumer_id => consumers.id)
#  fk_rails_...  (schedule_id => schedules.id)
#
