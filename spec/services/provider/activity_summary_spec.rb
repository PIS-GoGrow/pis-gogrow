# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::ActivitySummary do
  fixtures :users, :companies, :providers, :consumers, :menus

  let(:provider) { providers(:tuviandita) }
  let(:month) { Date.new(2026, 6, 1) }
  let(:summary) { described_class.new(provider, month.all_month) }

  def dish(name, provider: self.provider, base_menu: nil)
    Menu.create!(provider:, base_menu:, name:, description: "Casero", price: 300)
  end

  def order(menu, date, status: :confirmed)
    Order.create!(
      consumer: consumers(:one),
      schedule: Schedule.find_or_create_by!(menu:, date:),
      status:,
      rejection_reason: (:out_of_stock if status == :rejected),
      delivery_method: :office,
      amount: 1,
      price: menu.price,
      discounted_price: menu.price
    )
  end

  def review(menu, rating, created_at)
    Review.create!(menu:, rating:, created_at:)
  end

  describe "#orders_count" do
    it "cuenta los pedidos del proveedor que se entregan en el mes, sin cancelados ni rechazados" do
      milanesa = menus(:milanesa)
      order(milanesa, month)
      order(milanesa, month.end_of_month, status: :pending)
      order(milanesa, month + 3, status: :cancelled)
      order(milanesa, month + 4, status: :rejected)
      order(milanesa, month - 1)
      order(milanesa, month.next_month)
      order(dish("Torta", provider: providers(:endulzate)), month + 5)

      expect(summary.orders_count).to eq(2)
    end

    it "toma la fecha de entrega guardada cuando el pedido perdió su publicación" do
      order(menus(:milanesa), month + 2).update_columns(schedule_id: nil)

      expect(summary.orders_count).to eq(1)
    end
  end

  describe "#dishes_count" do
    it "cuenta los platos distintos con al menos un pedido válido, con sus variantes como un mismo plato" do
      milanesa = menus(:milanesa)
      variant = dish("Milanesa de pollo", base_menu: milanesa)
      wok = dish("Wok de verduras")
      order(milanesa, month)
      order(milanesa, month + 1)
      order(variant, month + 2)
      order(wok, month + 3, status: :cancelled)
      order(dish("Lasaña"), month.next_month)

      expect(summary.dishes_count).to eq(1)
    end
  end

  describe "#average_rating" do
    it "promedia las reseñas de los platos del proveedor escritas en el mes, con un decimal" do
      milanesa = menus(:milanesa)
      review(milanesa, 5, month.in_time_zone)
      review(milanesa, 4, month.end_of_month.in_time_zone.change(hour: 23, min: 30))
      review(milanesa, 4, month.in_time_zone.change(day: 10))
      review(milanesa, nil, month.in_time_zone.change(day: 11))
      review(milanesa, 1, month.prev_month.end_of_month.in_time_zone.change(hour: 23, min: 30))
      review(menus(:sorrentinos), 1, month.in_time_zone.change(day: 12))

      expect(summary.average_rating).to eq(4.3)
    end

    it "es nil sin reseñas en el mes" do
      expect(summary.average_rating).to be_nil
    end
  end

  describe "#status_counts" do
    it "cuenta todos los pedidos del mes por estado" do
      milanesa = menus(:milanesa)
      order(milanesa, month, status: :pending)
      order(milanesa, month + 1)
      order(milanesa, month + 2)
      order(milanesa, month + 3, status: :cancelled)
      order(milanesa, month + 4, status: :rejected)
      order(milanesa, month.next_month, status: :rejected)

      expect(summary.status_counts).to eq(pending: 1, confirmed: 2, cancelled: 1, rejected: 1)
    end

    it "devuelve ceros sin pedidos en el mes" do
      expect(summary.status_counts).to eq(pending: 0, confirmed: 0, cancelled: 0, rejected: 0)
    end
  end

  describe "#top_dishes" do
    it "ordena los cinco platos con más pedidos válidos, y alfabéticamente si empatan" do
      counts = { "Wok de verduras" => 3, "Ñoquis" => 2, "Albóndigas" => 2, "Lasaña" => 2, "Pasta" => 1, "Sorrentinos" => 1 }
      counts.each do |name, count|
        menu = dish(name)
        count.times { order(menu, month + it) }
      end
      order(Menu.find_by!(name: "Pasta"), month + 5, status: :cancelled)

      expect(summary.top_dishes.map { [ it.name, it.orders_count ] }).to eq(
        [ [ "Wok de verduras", 3 ], [ "Albóndigas", 2 ], [ "Lasaña", 2 ], [ "Ñoquis", 2 ], [ "Pasta", 1 ] ]
      )
    end

    it "suma los pedidos de una variante a su plato y muestra el nombre del plato" do
      milanesa = menus(:milanesa)
      order(milanesa, month)
      order(dish("Milanesa de pollo", base_menu: milanesa), month + 1)

      expect(summary.top_dishes.map { [ it.name, it.orders_count ] }).to eq([ [ milanesa.name, 2 ] ])
    end
  end

  describe "#top_rated_dishes" do
    it "ordena los cinco platos mejor valorados del mes, luego por cantidad de reseñas y luego por nombre" do
      at = month.in_time_zone.change(day: 15)
      { "Wok" => [ 5 ], "Lasaña" => [ 5, 5 ], "Risotto" => [ 5, 4 ], "Bife" => [ 4, 5 ], "Pasta" => [ 4 ], "Guiso" => [ 3 ] }.each do |name, ratings|
        menu = dish(name)
        ratings.each { review(menu, it, at) }
      end

      expect(summary.top_rated_dishes.map { [ it.name, it.rating ] }).to eq(
        [ [ "Lasaña", 5.0 ], [ "Wok", 5.0 ], [ "Bife", 4.5 ], [ "Risotto", 4.5 ], [ "Pasta", 4.0 ] ]
      )
    end

    it "no incluye reseñas de otro mes ni de otro proveedor" do
      review(menus(:milanesa), 5, month.next_month.in_time_zone)
      review(menus(:sorrentinos), 5, month.in_time_zone.change(day: 3))

      expect(summary.top_rated_dishes).to be_empty
    end
  end

  describe "con un rango que no es un mes" do
    it "cuenta los pedidos de un rango de varios días que cruza de mes" do
      milanesa = menus(:milanesa)
      order(milanesa, Date.new(2026, 6, 1))
      order(milanesa, Date.new(2026, 6, 2))
      order(milanesa, Date.new(2026, 6, 30))
      order(milanesa, Date.new(2026, 7, 4))
      order(milanesa, Date.new(2026, 7, 5))

      expect(described_class.new(provider, Date.new(2026, 6, 2)..Date.new(2026, 7, 4)).orders_count).to eq(3)
    end

    it "cuenta los pedidos y las reseñas de un solo día" do
      milanesa = menus(:milanesa)
      day = Date.new(2026, 6, 10)
      order(milanesa, day)
      order(milanesa, day + 1)
      review(milanesa, 5, day.in_time_zone.change(hour: 12))
      review(milanesa, 1, (day + 1).in_time_zone)
      summary = described_class.new(provider, day..day)

      expect([ summary.orders_count, summary.average_rating ]).to eq([ 1, 5.0 ])
    end

    it "toma las reseñas del primer día desde las 00:00 y las del último hasta las 23:59 de Montevideo" do
      milanesa = menus(:milanesa)
      from = Date.new(2026, 6, 2)
      to = Date.new(2026, 7, 4)
      review(milanesa, 5, from.in_time_zone)
      review(milanesa, 3, to.in_time_zone.change(hour: 23, min: 59))
      review(milanesa, 1, from.in_time_zone - 1.minute)
      review(milanesa, 1, (to + 1).in_time_zone)

      expect(described_class.new(provider, from..to).average_rating).to eq(4.0)
    end
  end

  describe ".first_delivery_date" do
    it "es la primera fecha de entrega de los pedidos del proveedor" do
      order(menus(:milanesa), Date.new(2026, 4, 20))
      order(menus(:milanesa), Date.new(2026, 5, 3))
      order(dish("Torta", provider: providers(:endulzate)), Date.new(2026, 1, 2))

      expect(described_class.first_delivery_date(provider)).to eq(Date.new(2026, 4, 20))
    end

    it "es nil para un proveedor sin pedidos" do
      expect(described_class.first_delivery_date(providers(:office_provider))).to be_nil
    end
  end
end
