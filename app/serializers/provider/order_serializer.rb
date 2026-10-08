# frozen_string_literal: true

class Provider::OrderSerializer < ApplicationSerializer
  typelize_from Order

  attributes :id, :status, :amount, :notes, :delivery_method

  typelize :number
  attribute :price do |order|
    order.price.to_f
  end

  typelize :string, nullable: true
  attribute :date do |order|
    order.schedule&.date&.iso8601
  end

  typelize :string
  attribute :time do |order|
    order.created_at.strftime("%H:%M")
  end

  typelize :string
  attribute :consumer_name do |order|
    order.consumer.user.name
  end

  typelize :string, nullable: true
  attribute :consumer_company do |order|
    order.consumer.company&.name
  end

  typelize :string
  attribute :menu_name do |order|
    order.menu_name.to_s
  end

  typelize :string, nullable: true
  attribute :address do |order|
    order.address.presence || order.consumer.address
  end
end
