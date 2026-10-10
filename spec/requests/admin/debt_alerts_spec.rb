# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::DebtAlerts", type: :request do
  fixtures :users, :companies, :admins, :consumers, :providers

  let(:company) { companies(:gogrow) }
  let(:consumer) { consumers(:one) }

  before { sign_in users(:admin), role: :admin }

  describe "GET /admin/benefit_configurations" do
    it "expone el monto de alerta de deuda de la compañía" do
      get admin_benefit_configurations_path

      expect(inertia).to have_props(debt_alert_threshold: 2000)
    end
  end

  describe "PATCH /admin/debt_alert" do
    it "actualiza el monto y vuelve a la pantalla de subsidios" do
      patch admin_debt_alert_path, params: { company: { debt_alert_threshold: 3500 } }

      expect(response).to redirect_to(admin_benefit_configurations_path)
      expect(company.reload.debt_alert_threshold).to eq(3500)

      follow_redirect!
      expect(inertia).to have_flash(notice: "Monto de alerta de deuda actualizado")
    end

    it "avisa a los empleados que pasan a superar el nuevo monto" do
      consumer.accounts.destroy_all
      Account.create!(owner: consumer, provider: providers(:tuviandita), amount: 1500)

      patch admin_debt_alert_path, params: { company: { debt_alert_threshold: 1000 } }

      expect(consumer.user.notifications.active.where(event: "debt_threshold_exceeded")).to exist
    end

    it "rechaza un monto que no es positivo" do
      patch admin_debt_alert_path, params: { company: { debt_alert_threshold: 0 } }

      expect(company.reload.debt_alert_threshold).to eq(2000)

      follow_redirect!
      expect(inertia.props[:errors]).to include("debt_alert_threshold" => [ "debe ser mayor que 0" ])
    end

    it "no deja entrar a un empleado" do
      sign_in users(:one), role: :consumer

      patch admin_debt_alert_path, params: { company: { debt_alert_threshold: 1000 } }

      expect(company.reload.debt_alert_threshold).to eq(2000)
    end
  end
end
