# frozen_string_literal: true

require "rails_helper"

RSpec.describe Menus::Import::SavedMenus do
  fixtures :users, :providers, :menus, :schedules, :orders

  let(:provider) { providers(:tuviandita) }
  let(:milanesa) { menus(:milanesa) }

  def saved = described_class.call(provider:)

  it "trae los platos guardados del proveedor con su nombre" do
    expect(saved.map { it[:name] }).to include("Milanesa con papas fritas")
  end

  it "no trae los platos de otro proveedor" do
    expect(saved.map { it[:name] }).not_to include("Sorrentinos artesanales")
  end

  it "no trae los platos archivados" do
    milanesa.update!(archived_at: Time.current)

    expect(saved.map { it[:id] }).not_to include(milanesa.id)
  end

  describe "la agenda que ya tiene el plato" do
    it "queda en none cuando no tiene" do
      entry = saved.find { it[:id] == milanesa.id }

      expect(entry[:agenda]).to eq(described_class::NO_AGENDA)
    end

    it "la devuelve como semanal, desde hoy si empezó antes" do
      milanesa.agendas.create!(weekdays: [ 1, 3 ], starts_on: 1.week.ago.to_date)

      entry = saved.find { it[:id] == milanesa.id }

      expect(entry[:agenda]).to include(
        mode: "weekly",
        weekdays: [ 1, 3 ],
        starts_on: Date.current.iso8601,
        ends_on: nil
      )
    end

    it "la devuelve como rango cuando tiene fecha de fin" do
      milanesa.agendas.create!(weekdays: [ 2 ], starts_on: Date.current, ends_on: 1.week.from_now.to_date)

      entry = saved.find { it[:id] == milanesa.id }

      expect(entry[:agenda]).to include(mode: "range", ends_on: 1.week.from_now.to_date.iso8601)
    end
  end

  describe "los pedidos confirmados" do
    it "cuenta los que faltan entregar, para poder avisar antes de pisar el plato" do
      entry = saved.find { it[:id] == milanesa.id }

      expect(entry[:confirmed_orders]).to eq(milanesa.upcoming_orders_count(:confirmed))
    end

    it "deja en cero al plato que no tiene ninguno" do
      Order.joins(:schedule).where(schedules: { menu_id: milanesa.family_ids }).destroy_all

      expect(saved.find { it[:id] == milanesa.id }[:confirmed_orders]).to eq(0)
    end
  end
end
