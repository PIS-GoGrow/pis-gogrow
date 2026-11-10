# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Admin::Reports", type: :request do
  fixtures :users, :companies, :admins, :providers, :consumers

  let(:today) { Date.new(2026, 8, 20) }
  let(:wok) { Menu.create!(provider: providers(:tuviandita), name: "Wok", description: "Casero", price: 300) }
  let(:cake) { Menu.create!(provider: providers(:endulzate), name: "Torta", description: "Casera", price: 200) }

  around { |example| travel_to(today) { example.run } }

  def order(consumer, menu, date, status: :confirmed, amount: 1)
    Order.create!(
      consumer:,
      schedule: Schedule.find_or_create_by!(menu:, date:),
      status:,
      delivery_method: :office,
      amount:,
      price: menu.price * amount,
      discounted_price: 100 * amount
    )
  end

  describe "GET /rrhh/reportes" do
    it "manda a iniciar sesión sin sesión iniciada" do
      get admin_reports_path

      expect(response).to redirect_to(admin_welcome_path)
    end

    it "no deja entrar a un empleado" do
      sign_in users(:one), role: :consumer

      get admin_reports_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("flash.no_permission"))
    end

    it "no deja entrar a un proveedor" do
      sign_in users(:provider_user), role: :provider

      get admin_reports_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("flash.no_permission"))
    end

    context "con rol de RR. HH." do
      before do
        sign_in users(:admin), role: :admin

        order(consumers(:one), wok, Date.new(2026, 6, 10))
        order(consumers(:one), wok, Date.new(2026, 8, 3), amount: 2)
        order(consumers(:one), cake, Date.new(2026, 8, 25))
        order(consumers(:other), cake, Date.new(2026, 8, 5), status: :pending)
        order(consumers(:other), wok, Date.new(2026, 8, 6), status: :cancelled)
      end

      it "muestra el mes actual por defecto, con sus límites y los presets" do
        get admin_reports_path

        expect(inertia).to render_component("admin/reports/index")
        expect(inertia).to have_props(
          from: "2026-08-01",
          to: "2026-08-31",
          default_from: "2026-08-01",
          default_to: "2026-08-31",
          min: "2026-06-10",
          max: "2026-08-31",
          month_label: "Agosto 2026",
          presets: [
            { key: "today", from: "2026-08-20", to: "2026-08-20" },
            { key: "yesterday", from: "2026-08-19", to: "2026-08-19" },
            { key: "this_week", from: "2026-08-16", to: "2026-08-20" },
            { key: "this_month", from: "2026-08-01", to: "2026-08-31" },
            { key: "last_month", from: "2026-07-01", to: "2026-07-31" }
          ],
          summary: { adhesion: 50, participants: 1, employees: 2, orders: 2, meals: 3, company_amount: 500.0, employee_amount: 300.0 },
          providers: [
            { id: providers(:tuviandita).id, name: "Provider User", orders: 1, meals: 2, company_amount: 400.0 },
            { id: providers(:endulzate).id, name: "Other Provider User", orders: 1, meals: 1, company_amount: 100.0 }
          ]
        )
      end

      it "usa el rango pedido, sin etiqueta de mes si no es un mes completo" do
        get admin_reports_path(desde: "2026-06-10", hasta: "2026-08-04")

        expect(inertia).to have_props(
          from: "2026-06-10",
          to: "2026-08-04",
          month_label: nil,
          summary: { adhesion: 50, participants: 1, employees: 2, orders: 2, meals: 3, company_amount: 600.0, employee_amount: 300.0 },
          providers: [ { id: providers(:tuviandita).id, name: "Provider User", orders: 2, meals: 3, company_amount: 600.0 } ]
        )
      end

      it "cae al mes actual con fechas inválidas o invertidas" do
        [ { desde: "ayer", hasta: "2026-08-04" }, { desde: "2026-08-10", hasta: "2026-08-01" } ].each do |params|
          get admin_reports_path(params)

          expect(inertia).to have_props(from: "2026-08-01", to: "2026-08-31")
        end
      end

      it "recorta lo que queda fuera de los límites" do
        get admin_reports_path(desde: "2025-01-01", hasta: "2027-01-01")

        expect(inertia).to have_props(from: "2026-06-10", to: "2026-08-31")
      end

      it "queda en cero en un período sin actividad, sin datos de otro período" do
        get admin_reports_path(desde: "2026-07-01", hasta: "2026-07-31")

        expect(inertia).to have_props(
          month_label: "Julio 2026",
          summary: { adhesion: 0, participants: 0, employees: 2, orders: 0, meals: 0, company_amount: 0.0, employee_amount: 0.0 },
          providers: []
        )
      end

      it "ignora pedidos de empleados de otras empresas en el período" do
        other_company = Company.create!(name: "Otra Empresa", address: "Av Italia 1234")
        other_user = User.create!(name: "Empleado Externo", email: "externo@example.com", password: "secret-password-123")
        other_consumer = Consumer.create!(user: other_user, company: other_company)
        order(other_consumer, wok, Date.new(2026, 8, 10), amount: 10)

        get admin_reports_path

        expect(inertia).to have_props(
          summary: { adhesion: 50, participants: 1, employees: 2, orders: 2, meals: 3, company_amount: 500.0, employee_amount: 300.0 }
        )
      end

      it "maneja parámetros parciales o estructuras de datos inesperadas cayendo al mes actual" do
        [
          { desde: "2026-08-01" },
          { hasta: "2026-08-31" },
          { desde: [ "2026-08-01" ], hasta: "2026-08-31" },
          { desde: "null", hasta: "undefined" }
        ].each do |invalid_params|
          get admin_reports_path(invalid_params)

          expect(response).to have_http_status(:ok)
          expect(inertia).to have_props(from: "2026-08-01", to: "2026-08-31")
        end
      end
    end
  end
end
