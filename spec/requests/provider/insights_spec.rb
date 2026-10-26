# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Provider::Insights", type: :request do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders, :reviews, :admins

  let(:provider) { providers(:tuviandita) }
  let(:month) { Date.current.prev_month(2).beginning_of_month }
  let(:default_from) { Date.current.beginning_of_month.iso8601 }
  let(:default_to) { Date.current.end_of_month.iso8601 }

  def range(from, to)
    { desde: from.iso8601, hasta: to.iso8601 }
  end

  def dish(name, provider: self.provider)
    Menu.create!(provider:, name:, description: "Casero", price: 300)
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

  describe "GET /proveedor/inicio/hallazgos" do
    it "manda a iniciar sesión sin sesión iniciada" do
      get provider_insights_path

      expect(response).to redirect_to(provider_sign_in_path)
    end

    it "no deja entrar a un empleado" do
      sign_in users(:one), role: :consumer

      get provider_insights_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("flash.no_permission"))
    end

    it "no deja entrar a RR. HH." do
      sign_in users(:admin), role: :admin

      get provider_insights_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("flash.no_permission"))
    end

    context "con rol de proveedor" do
      let(:wok) { dish("Wok de verduras") }
      let(:lasagna) { dish("Lasaña veggie") }

      before do
        sign_in users(:provider_user), role: :provider

        2.times { order(wok, month + it) }
        order(lasagna, month + 2)
        order(lasagna, month + 3, status: :cancelled)
        order(wok, month + 4, status: :rejected)
        order(wok, month.next_month)
        order(dish("Torta", provider: providers(:endulzate)), month + 5)
        Review.create!(menu: wok, rating: 5, created_at: month.in_time_zone.change(day: 10))
        Review.create!(menu: lasagna, rating: 4, created_at: month.in_time_zone.change(day: 11))
        Review.create!(menu: lasagna, rating: 5, created_at: month.next_month.in_time_zone)
      end

      it "muestra el mes actual por defecto, con sus límites y los presets" do
        get provider_insights_path

        today = Date.current
        expect(inertia).to render_component("provider/insights/index")
        expect(inertia).to have_props(
          from: default_from,
          to: default_to,
          default_from:,
          default_to:,
          min: month.iso8601,
          max: default_to,
          month_label: I18n.l(today, format: "%B %Y").capitalize,
          presets: [
            { key: "today", from: today.iso8601, to: today.iso8601 },
            { key: "yesterday", from: today.yesterday.iso8601, to: today.yesterday.iso8601 },
            { key: "this_week", from: today.beginning_of_week(:sunday).iso8601, to: today.iso8601 },
            { key: "this_month", from: default_from, to: default_to },
            { key: "last_month", from: today.prev_month.beginning_of_month.iso8601, to: today.prev_month.end_of_month.iso8601 }
          ]
        )
      end

      it "calcula un mes completo solo con los pedidos y reseñas del proveedor, sin los de otro proveedor" do
        get provider_insights_path(range(month, month.end_of_month))

        expect(inertia).to have_props(
          from: month.iso8601,
          to: month.end_of_month.iso8601,
          month_label: I18n.l(month, format: "%B %Y").capitalize,
          orders_count: 3,
          dishes_count: 2,
          average_rating: 4.5,
          top_dishes: [
            { id: wok.id, name: "Wok de verduras", orders_count: 2 },
            { id: lasagna.id, name: "Lasaña veggie", orders_count: 1 }
          ],
          top_rated_dishes: [
            { id: wok.id, name: "Wok de verduras", rating: 5.0 },
            { id: lasagna.id, name: "Lasaña veggie", rating: 4.0 }
          ]
        )
      end

      it "calcula un rango custom que cruza de mes, sin etiqueta de mes" do
        get provider_insights_path(range(month + 1, month.next_month))

        expect(inertia).to have_props(
          from: (month + 1).iso8601,
          to: month.next_month.iso8601,
          month_label: nil,
          orders_count: 3,
          average_rating: 4.7
        )
      end

      it "cuenta los mismos pedidos que el listado de Pedidos para ese mes" do
        get provider_insights_path(range(month, month.end_of_month))
        orders_count = inertia.props[:orders_count]

        get provider_orders_path
        listed = inertia.props[:past_orders].count do
          it[:status].in?(%w[pending confirmed]) && month.all_month.cover?(Date.iso8601(it[:date]))
        end

        expect(orders_count).to eq(listed)
      end

      [
        { desde: "2026-13-01", hasta: "2026-13-05" },
        { desde: "septiembre", hasta: "octubre" },
        { desde: "2026-09-01" }
      ].each do |invalid|
        it "vuelve al mes actual con #{invalid.inspect}" do
          get provider_insights_path(invalid)

          expect(inertia).to have_props(from: default_from, to: default_to)
        end
      end

      it "vuelve al mes actual con un rango invertido" do
        get provider_insights_path(desde: (month + 5).iso8601, hasta: month.iso8601)

        expect(inertia).to have_props(from: default_from, to: default_to)
      end

      it "recorta a los límites un rango que empieza antes de la primera entrega y termina después del mes actual" do
        get provider_insights_path(range(month.prev_month, Date.current.next_month.end_of_month))

        expect(inertia).to have_props(from: month.iso8601, to: default_to, month_label: nil)
      end

      it "vuelve al mes actual con un rango entero después del mes actual" do
        get provider_insights_path(range(Date.current.next_month, Date.current.next_month + 3))

        expect(inertia).to have_props(from: default_from, to: default_to)
      end

      it "vuelve al mes actual con un rango entero antes de la primera entrega" do
        get provider_insights_path(range(month.prev_month, month - 1))

        expect(inertia).to have_props(from: default_from, to: default_to)
      end
    end

    it "muestra ceros y listas vacías a un proveedor sin actividad" do
      sign_in users(:office_provider_user), role: :provider

      get provider_insights_path

      expect(inertia).to have_props(
        from: default_from,
        to: default_to,
        min: default_from,
        max: default_to,
        orders_count: 0,
        dishes_count: 0,
        average_rating: nil,
        top_dishes: [],
        top_rated_dishes: []
      )
    end
  end
end
