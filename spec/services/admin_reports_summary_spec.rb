# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminReportsSummary do
  fixtures :users, :companies, :providers, :consumers

  let(:company) { Company.create!(name: "Acme", address: "Rambla 1") }
  let(:month) { Date.new(2026, 8, 1) }
  let!(:ana) { employee("Ana") }
  let!(:bruno) { employee("Bruno") }
  let!(:carla) { employee("Carla") }
  let!(:diego) { employee("Diego") }
  let(:tuviandita) { dish(providers(:tuviandita), 300) }
  let(:endulzate) { dish(providers(:endulzate), 200) }

  def employee(name, company: self.company)
    user = User.create!(name:, email: "#{name.parameterize}-#{company.id}@example.com", password: "secret-password-123")
    Consumer.create!(user:, company:)
  end

  def dish(provider, price)
    Menu.create!(provider:, name: "Plato #{provider.id}", description: "Casero", price:)
  end

  def order(consumer, menu, date, amount: 1, discounted: nil, status: :confirmed)
    price = menu.price * amount
    Order.create!(
      consumer:,
      schedule: Schedule.find_or_create_by!(menu:, date:),
      status:,
      rejection_reason: (:out_of_stock if status == :rejected),
      delivery_method: :office,
      amount:,
      price:,
      discounted_price: discounted || price
    )
  end

  def summary(range = month.all_month) = described_class.new(company, range)

  context "con pedidos en el mes" do
    before do
      order(ana, tuviandita, month + 1, amount: 2, discounted: 150)
      order(ana, endulzate, month + 2, discounted: 50)
      order(bruno, endulzate, month + 3, amount: 3, discounted: 300)
      order(carla, tuviandita, month + 4, status: :pending)
      order(carla, tuviandita, month + 5, status: :cancelled)
      order(diego, endulzate, month + 6, status: :rejected)
      order(employee("Eva", company: companies(:gogrow)), tuviandita, month + 7)
    end

    it "calcula la adhesión con los empleados que tienen pedidos confirmados sobre los empleados de la empresa" do
      expect(summary).to have_attributes(participants_count: 2, employees_count: 4, adhesion: 50)
    end

    it "cuenta solo los pedidos confirmados de la empresa y lo que paga cada parte" do
      expect(summary).to have_attributes(orders_count: 3, meals: 6, company_amount: 450 + 150 + 300, employee_amount: 150 + 50 + 300)
    end

    it "desglosa por proveedor, de más a menos viandas, y suma los totales" do
      rows = summary.by_provider

      expect(rows.map(&:to_h)).to eq([
        { provider_id: providers(:endulzate).id, name: "Other Provider User", orders_count: 2, meals: 4, company_amount: 450 },
        { provider_id: providers(:tuviandita).id, name: users(:provider_user).name, orders_count: 1, meals: 2, company_amount: 450 }
      ])
      expect(rows.sum(&:orders_count)).to eq(summary.orders_count)
      expect(rows.sum(&:meals)).to eq(summary.meals)
      expect(rows.sum(&:company_amount)).to eq(summary.company_amount)
    end

    it "toma un rango que cruza meses por fecha de entrega" do
      order(bruno, tuviandita, month.next_month + 1)
      order(bruno, tuviandita, month.next_month + 20)

      range = summary((month + 2)..(month.next_month + 1))

      expect(range).to have_attributes(orders_count: 3, meals: 5, participants_count: 2)
    end

    it "toma un rango de un solo día" do
      day = summary((month + 3)..(month + 3))

      expect(day).to have_attributes(orders_count: 1, meals: 3, company_amount: 300, adhesion: 25)
      expect(day.by_provider.map(&:provider_id)).to eq([ providers(:endulzate).id ])
    end
  end

  it "desempata el orden por nombre del proveedor" do
    order(ana, endulzate, month + 1)
    order(bruno, tuviandita, month + 1)

    expect(summary.by_provider.map(&:name)).to eq([ "Other Provider User", users(:provider_user).name ].sort)
  end

  it "queda en cero sin actividad en el rango" do
    order(ana, tuviandita, month.prev_month + 3)
    order(bruno, tuviandita, month + 3, status: :pending)

    expect(summary).to have_attributes(adhesion: 0, participants_count: 0, orders_count: 0, meals: 0, company_amount: 0, employee_amount: 0, by_provider: [])
  end

  it "da adhesión 0 si la empresa no tiene empleados" do
    empty = Company.create!(name: "Vacía", address: "Rambla 2")

    expect(described_class.new(empty, month.all_month)).to have_attributes(employees_count: 0, adhesion: 0, orders_count: 0)
  end

  it "computa la totalidad del gasto a la empresa cuando el subsidio es del 100%" do
    order(ana, tuviandita, month + 1, amount: 1, discounted: 0)

    expect(summary).to have_attributes(company_amount: 300, employee_amount: 0)
  end

  it "toma la fecha de entrega directamente de la orden cuando el schedule fue eliminado" do
    ord = order(ana, tuviandita, month + 2, discounted: 100)
    ord.schedule.destroy!

    expect(summary).to have_attributes(orders_count: 1, meals: 1, company_amount: 200, employee_amount: 100)
  end

  it "cuenta como un solo participante a un empleado con múltiples pedidos en el período" do
    order(ana, tuviandita, month + 1)
    order(ana, endulzate, month + 2)

    expect(summary).to have_attributes(orders_count: 2, meals: 2, participants_count: 1, adhesion: 25)
  end

  it "aísla los pedidos de otras empresas en el mismo período" do
    other_company = Company.create!(name: "Empresa Vecina", address: "Rivera 1234")
    other_employee = employee("Lucas", company: other_company)
    order(other_employee, tuviandita, month + 1, amount: 5, discounted: 0)

    expect(summary).to have_attributes(orders_count: 0, meals: 0, company_amount: 0, participants_count: 0, by_provider: [])
  end
end
