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
    xlsx_rows(export.to_xlsx)
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

  describe "#to_xlsx" do
    it "writes the header on a frozen first row of a sheet named Pedidos" do
      xlsx = export([ order ]).to_xlsx

      expect(rows(export([ order ])).first).to eq([
        "Código", "Fecha de entrega", "Hora del pedido", "Estado", "Empleado", "Empresa", "Plato",
        "Opciones", "Cantidad", "Entrega", "Dirección", "Notas", "Monto"
      ])
      Zip::File.open_buffer(StringIO.new(xlsx)) do |zip|
        expect(zip.read("xl/workbook.xml")).to include('name="Pedidos"')
        expect(zip.read("xl/worksheets/sheet1.xml")).to include('state="frozen"', 'ySplit="1"')
      end
    end

    it "writes the operational data of each order with real dates and numbers, without contact data" do
      options = [
        { "group_id" => 1, "name" => "Guarnición", "values" => [ "Papas", "Ensalada" ] },
        { "group_id" => 2, "name" => "Salsa", "values" => [ "Criolla" ] }
      ]
      xlsx = export([ order(selected_options: options, notes: "Timbre 2", price: 1234.5, amount: 2) ]).to_xlsx
      row = xlsx_cells(xlsx)[1]

      expect(row.map(&:value)).to eq([
        "PED-1247", Date.new(2026, 10, 26), "21:30", "Pendiente", "Test User", "GoGrow", "Milanesa con papas fritas",
        "Guarnición: Papas, Ensalada; Salsa: Criolla", 2, "Oficina", "Julio Herrera y Reissig 565", "Timbre 2", 1234.5
      ])
      expect(row[1].format).to eq("dd/mm/yyyy")
      expect(row[12].format).to eq("#,##0.00")
      expect(xlsx_rows(xlsx).flatten.join).not_to include("one@example.com")
    end

    it "keeps text that Excel would read as a formula as plain text" do
      cell = xlsx_cells(export([ order(notes: "=HYPERLINK(\"x\")") ]).to_xlsx)[1][11]

      expect(cell.value).to eq("=HYPERLINK(\"x\")")
      expect(cell.formula).to be_nil
    end

    it "ends with the totals of the exported orders as numbers" do
      orders = [ order(id: 1, amount: 2, price: 601), order(id: 2, amount: 1, price: 300.50, status: :cancelled) ]
      total = xlsx_cells(export(orders).to_xlsx).last

      expect(total.map(&:value)).to eq([ "Total", nil, nil, nil, nil, nil, nil, nil, 3, nil, nil, nil, 901.5 ])
      expect(total[12].format).to eq("#,##0.00")
    end

    it "writes headers and a zero total without orders" do
      expect(rows(export([])).size).to eq(2)
      expect(rows(export([])).last).to include("Total", 0)
    end
  end

  describe "#filename" do
    it "names the provider, the period, the delivery range and the generation time" do
      orders = [ order(id: 1, delivery_date: Date.new(2026, 11, 3)), order(id: 2, delivery_date: Date.new(2026, 10, 27)) ]

      expect(export(orders).filename)
        .to eq("pedidos_provider-user_proximos_2026-10-27_al_2026-11-03_generado_2026-10-26_2130.xlsx")
    end

    it "leaves the range out without orders" do
      history = described_class.new([], provider:, period: :history)

      expect(history.filename).to eq("pedidos_provider-user_historial_generado_2026-10-26_2130.xlsx")
    end
  end
end
