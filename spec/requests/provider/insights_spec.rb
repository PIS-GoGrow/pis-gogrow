# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Provider::Insights", type: :request do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules, :orders, :reviews, :admins

  let(:provider) { providers(:tuviandita) }
  let(:month) { Date.current.prev_month(2).beginning_of_month }
  let(:period) { month.strftime("%Y-%m") }
  let(:current_period) { Date.current.strftime("%Y-%m") }

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

  describe "GET /proveedor/hallazgos" do
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

      it "muestra el mes actual por defecto y ofrece los meses desde la primera entrega" do
        get provider_insights_path

        expect(inertia).to render_component("provider/insights/index")
        expect(inertia).to have_props(
          period: current_period,
          current_period:,
          periods: [
            { key: current_period, label: I18n.l(Date.current, format: "%B %Y").capitalize },
            { key: Date.current.prev_month.strftime("%Y-%m"), label: I18n.l(Date.current.prev_month, format: "%B %Y").capitalize },
            { key: period, label: I18n.l(month, format: "%B %Y").capitalize }
          ]
        )
      end

      it "calcula el período elegido solo con los pedidos y reseñas del proveedor en ese mes" do
        get provider_insights_path(period:)

        expect(inertia).to have_props(
          period:,
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

      it "cuenta los mismos pedidos que el listado de Pedidos para ese mes" do
        get provider_insights_path(period:)
        orders_count = inertia.props[:orders_count]

        get provider_orders_path
        listed = inertia.props[:past_orders].count do
          it[:status].in?(%w[pending confirmed]) && month.all_month.cover?(Date.iso8601(it[:date]))
        end

        expect(orders_count).to eq(listed)
      end

      %w[2026-13 septiembre 2026-9].each do |invalid|
        it "vuelve al mes actual con el período #{invalid.inspect}" do
          get provider_insights_path(period: invalid)

          expect(inertia).to have_props(period: current_period)
        end
      end

      it "vuelve al mes actual con un período futuro" do
        get provider_insights_path(period: Date.current.next_month.strftime("%Y-%m"))

        expect(inertia).to have_props(period: current_period)
      end

      it "vuelve al mes actual con un período anterior a la primera entrega" do
        get provider_insights_path(period: month.prev_month.strftime("%Y-%m"))

        expect(inertia).to have_props(period: current_period)
      end
    end

    it "muestra ceros y listas vacías a un proveedor sin actividad" do
      sign_in users(:office_provider_user), role: :provider

      get provider_insights_path

      expect(inertia).to have_props(
        period: current_period,
        periods: [ { key: current_period, label: I18n.l(Date.current, format: "%B %Y").capitalize } ],
        orders_count: 0,
        dishes_count: 0,
        average_rating: nil,
        top_dishes: [],
        top_rated_dishes: []
      )
    end
  end
end
