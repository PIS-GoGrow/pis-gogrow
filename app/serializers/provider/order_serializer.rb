# frozen_string_literal: true

class Provider::OrderSerializer < ApplicationSerializer
  typelize_from Order

  attributes :id, :status, :amount, :notes

  typelize :number
  attribute :price do |order|
    order.price.to_f
  end

  typelize :string, nullable: true
  attribute :delivery_date do |order|
    date = order.schedule&.date

    if date.nil?
      nil
    elsif date == Date.current
      I18n.t("pages.provider_orders.index.today")
    elsif date == Date.current + 1.day
      I18n.t("pages.provider_orders.index.tomorrow")
    else
      date.strftime(I18n.t("pages.provider_orders.index.date"))
    end
  end

  typelize :string
  attribute :time do |order|
    order.created_at.strftime("%H:%M")
  end

  typelize :string
  attribute :consumer_name do |order|
    order.consumer.user.name
  end

  typelize :string
  attribute :menu_name do |order|
    order.schedule.menu.name
  end

  typelize :string, nullable: true
  attribute :address do |order|
    order.address.presence || order.consumer.address
  end
end
