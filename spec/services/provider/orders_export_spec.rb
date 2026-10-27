# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::OrdersExport do
  fixtures :users, :companies, :providers, :consumers, :menus, :schedules

  let(:provider) { providers(:tuviandita) }

  before { travel_to Time.zone.local(2026, 10, 26, 21, 30) }

  def order(**attributes)
    Order.new(
      id: 1247,
      consumer: consumers(:one),
      schedule: schedules(:today),
      delivery_date: Date.current,
      status: :pending,
      delivery_method: :office,
      amount: 1,
      price: 300.50,
      created_at: Time.current,
      **attributes
    )
  end

  def export(orders, **filters)
    described_class.new(orders, provider:, period: :upcoming, **filters)
  end

  def rows(export)
    CSV.parse(export.to_csv.delete_prefix("﻿"), col_sep: ";")
  end

  describe "#orders" do
    let(:pending_home) { order(id: 1, status: :pending, delivery_method: :home, notes: "Sin cebolla") }
    let(:confirmed_office) { order(id: 2, status: :confirmed, consumer: consumers(:other), address: nil) }
    let(:cancelled_home) { order(id: 3, status: :cancelled, delivery_method: :home) }
    let(:all) { [ pending_home, confirmed_office, cancelled_home ] }

    it "keeps every order without filters" do
      expect(export(all).orders).to eq(all)
    end

    it "filters by exact status and delivery method" do
      expect(export(all, status: "pending").orders).to eq([ pending_home ])
      expect(export(all, status: "confirmed").orders).to eq([ confirmed_office ])
      expect(export(all, delivery: "home").orders).to eq([ pending_home, cancelled_home ])
      expect(export(all, status: "pending", delivery: "office").orders).to be_empty
    end

    it "ignores values outside the allowed lists" do
      expect(export(all, status: "cancelled", delivery: "drone").orders).to eq(all)
    end

    it "requires every search word, ignoring case and accents" do
      expect(export(all, search: "CEBÓLLA").orders).to eq([ pending_home ])
      expect(export(all, search: "  milanesa   artigas ").orders).to eq([ confirmed_office ])
      expect(export(all, search: "milanesa marte").orders).to be_empty
    end

    it "searches the code and the translated labels shown on screen" do
      expect(export(all, search: "ped-2").orders).to eq([ confirmed_office ])
      expect(export(all, search: "cancelado casa").orders).to eq([ cancelled_home ])
    end
  end

  describe "#to_csv" do
    it "starts with a BOM and uses semicolons" do
      csv = export([ order ]).to_csv

      expect(csv).to start_with("﻿Código;Fecha de entrega;")
    end

    it "writes the operational data of each order without personal contact data" do
      options = [
        { "group_id" => 1, "name" => "Guarnición", "values" => [ "Papas", "Ensalada" ] },
        { "group_id" => 2, "name" => "Salsa", "values" => [ "Criolla" ] }
      ]
      row = rows(export([ order(selected_options: options, notes: "Timbre 2", price: 1234.5, amount: 2) ]))[1]

      expect(row).to eq([
        "PED-1247", "26/10/2026", "21:30", "Pendiente", "Test User", "GoGrow", "Milanesa con papas fritas",
        "Guarnición: Papas, Ensalada; Salsa: Criolla", "2", "Oficina", "Julio Herrera y Reissig 565", "Timbre 2", "1234,50"
      ])
      expect(row.join).not_to include("one@example.com")
    end

    it "keeps text that Excel would read as a formula as text" do
      row = rows(export([ order(notes: "=HYPERLINK(\"x\")") ]))[1]

      expect(row[11]).to eq("'=HYPERLINK(\"x\")")
    end

    it "ends with the totals of the exported orders" do
      orders = [ order(id: 1, amount: 2, price: 601), order(id: 2, amount: 1, price: 300.50, status: :cancelled) ]

      expect(rows(export(orders)).last).to eq([ "Total", nil, nil, nil, nil, nil, nil, nil, "3", nil, nil, nil, "901,50" ])
    end

    it "writes headers and a zero total without orders" do
      expect(rows(export([])).size).to eq(2)
      expect(rows(export([])).last).to include("Total", "0", "0,00")
    end
  end

  describe "#filename" do
    it "names the provider, the period, the delivery range and the generation time" do
      orders = [ order(id: 1, delivery_date: Date.new(2026, 11, 3)), order(id: 2, delivery_date: Date.new(2026, 10, 27)) ]

      expect(export(orders).filename)
        .to eq("pedidos_provider-user_proximos_2026-10-27_al_2026-11-03_generado_2026-10-26_2130.csv")
    end

    it "leaves the range out without orders" do
      history = described_class.new([], provider:, period: :history)

      expect(history.filename).to eq("pedidos_provider-user_historial_generado_2026-10-26_2130.csv")
    end
  end
end
