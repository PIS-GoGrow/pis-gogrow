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

  def order(consumer, menu, date, amount: 1, discounted: nil, status: :confirmed, delivery_method: :office, address: nil)
    price = menu.price * amount
    Order.create!(
      consumer:,
      schedule: Schedule.find_or_create_by!(menu:, date:),
      status:,
      rejection_reason: (:out_of_stock if status == :rejected),
      delivery_method:,
      address: (delivery_method == :home ? (address || "Calle Falsa 123") : nil),
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

    it "calcula el consumo diario y las modalidades de entrega" do
      expect(summary.daily_consumption).to eq([
        { date: (month + 1).to_s, orders: 1, meals: 2, company_amount: 450.0 },
        { date: (month + 2).to_s, orders: 1, meals: 1, company_amount: 150.0 },
        { date: (month + 3).to_s, orders: 1, meals: 3, company_amount: 300.0 }
      ])
      expect(summary.delivery_methods).to eq(
        office: { orders: 3, meals: 6 },
        home: { orders: 0, meals: 0 }
      )
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

  context "con un escenario de alto volumen de datos y pedidos diversos (stress test de consistencia)" do
    let(:stress_company) { Company.create!(name: "Empresa Grande S.A.", address: "Plaza Independencia 848") }
    let(:foreign_company) { Company.create!(name: "Empresa Externa Ltd", address: "18 de Julio 1000") }
    let(:stress_month) { Date.new(2026, 10, 1) }
    let(:stress_range) { stress_month.all_month }

    let(:third_provider) do
      user = User.create!(name: "Chef Express", email: "chef@express.com", password: "secret-password-123")
      Provider.create!(user:, home_delivery: true, onboarding_completed_at: 1.week.ago)
    end
    let(:gourmet) { dish(third_provider, 350) }

    it "garantiza la consistencia matemática, coherencia e invariantes entre todas las dimensiones" do
      # 25 empleados en la empresa objetivo y 10 en una externa
      employees = (1..25).map { |i| employee("Empleado #{i}", company: stress_company) }
      foreign_employees = (1..10).map { |i| employee("Externo #{i}", company: foreign_company) }

      # Menús disponibles de 3 proveedores
      dishes = [ tuviandita, endulzate, gourmet ] # precios: 300, 200, 350

      # 20 empleados activos (participantes) y 5 sin pedidos
      active_employees = employees.first(20)

      confirmed_orders = []

      # Generar 200 pedidos confirmados a lo largo del mes con variedad de parámetros
      200.times do |i|
        consumer = active_employees[i % active_employees.size]
        menu = dishes[i % dishes.size]
        date = stress_month + (i % 31).days # cubre del 1 al 31 de octubre
        amount = (i % 4) + 1 # 1 a 4 viandas
        delivery_method = (i % 3 == 0) ? :home : :office

        # Variedad de subsidio:
        # - 100% cubierto por la empresa (discounted = 0)
        # - Parcial (50% cubierto por empresa)
        # - 0% cubierto por la empresa (discounted = price total)
        total_price = menu.price * amount
        discounted = case i % 4
        when 0 then 0 # 100% subsidio
        when 1 then (total_price * 0.4).round(2) # 60% empresa, 40% empleado
        when 2 then (total_price * 0.5).round(2) # 50% empresa, 50% empleado
        else total_price # 0% subsidio
        end

        confirmed_orders << order(
          consumer,
          menu,
          date,
          amount:,
          discounted:,
          status: :confirmed,
          delivery_method:
        )
      end

      # Generar datos "ruido" que NO deben contaminar las estadísticas
      # 1. Pedidos pendientes en la misma empresa
      30.times do |i|
        order(employees[i % employees.size], dishes[i % dishes.size], stress_month + (i % 31).days, status: :pending)
      end

      # 2. Pedidos cancelados en la misma empresa
      20.times do |i|
        order(employees[i % employees.size], dishes[i % dishes.size], stress_month + (i % 31).days, status: :cancelled)
      end

      # 3. Pedidos rechazados en la misma empresa
      15.times do |i|
        order(employees[i % employees.size], dishes[i % dishes.size], stress_month + (i % 31).days, status: :rejected)
      end

      # 4. Pedidos confirmados de la empresa externa en las mismas fechas
      40.times do |i|
        order(foreign_employees[i % foreign_employees.size], dishes[i % dishes.size], stress_month + (i % 31).days, status: :confirmed)
      end

      # 5. Pedidos confirmados de la empresa antes del mes (septiembre) y después del mes (noviembre)
      20.times do |i|
        order(employees[i % employees.size], dishes[i % dishes.size], stress_month.prev_month + (i % 28).days, status: :confirmed)
        order(employees[i % employees.size], dishes[i % dishes.size], stress_month.next_month + (i % 28).days, status: :confirmed)
      end

      # Ejecutar el resumen
      report = described_class.new(stress_company, stress_range)

      # 1. Verificación de conteo de empleados y adhesión
      expect(report.employees_count).to eq(25)
      expect(report.participants_count).to eq(20)
      expect(report.adhesion).to eq(80) # 20 / 25 * 100

      # 2. Verificación de totales base
      expected_orders_count = confirmed_orders.size # 200
      expected_meals = confirmed_orders.sum(&:amount)
      expected_company_amount = confirmed_orders.sum { |o| o.price - o.discounted_price }
      expected_employee_amount = confirmed_orders.sum(&:discounted_price)

      expect(report.orders_count).to eq(expected_orders_count)
      expect(report.meals).to eq(expected_meals)
      expect(report.company_amount).to eq(expected_company_amount)
      expect(report.employee_amount).to eq(expected_employee_amount)

      # 3. Invariante Gasto Total: compañía + empleado = suma de precios de los pedidos
      expect(report.company_amount + report.employee_amount).to eq(confirmed_orders.sum(&:price))

      # 4. Invariante 1: Volumen de pedidos a través de todas las dimensiones
      daily_orders_sum = report.daily_consumption.sum { |d| d[:orders] }
      providers_orders_sum = report.by_provider.sum(&:orders_count)
      delivery_orders_sum = report.delivery_methods[:office][:orders] + report.delivery_methods[:home][:orders]

      expect(daily_orders_sum).to eq(report.orders_count)
      expect(providers_orders_sum).to eq(report.orders_count)
      expect(delivery_orders_sum).to eq(report.orders_count)

      # 5. Invariante 2: Volumen de viandas a través de todas las dimensiones
      daily_meals_sum = report.daily_consumption.sum { |d| d[:meals] }
      providers_meals_sum = report.by_provider.sum(&:meals)
      delivery_meals_sum = report.delivery_methods[:office][:meals] + report.delivery_methods[:home][:meals]

      expect(daily_meals_sum).to eq(report.meals)
      expect(providers_meals_sum).to eq(report.meals)
      expect(delivery_meals_sum).to eq(report.meals)

      # 6. Invariante 3: Monto de la empresa a través de las dimensiones que lo desglosan
      daily_amount_sum = report.daily_consumption.sum { |d| d[:company_amount] }.to_d
      providers_amount_sum = report.by_provider.sum(&:company_amount)

      expect(daily_amount_sum).to eq(report.company_amount)
      expect(providers_amount_sum).to eq(report.company_amount)

      # 7. Coherencia cronológica de la evolución diaria
      dates = report.daily_consumption.map { |d| d[:date] }
      expect(dates).to eq(dates.sort)
      expect(dates.all? { |d| stress_range.cover?(Date.parse(d)) }).to be(true)

      # Verificación puntual día por día
      confirmed_by_date = confirmed_orders.group_by { |o| o.delivery_date.to_s }
      report.daily_consumption.each do |day|
        expected_day_orders = confirmed_by_date[day[:date]]
        expect(day[:orders]).to eq(expected_day_orders.size)
        expect(day[:meals]).to eq(expected_day_orders.sum(&:amount))
        expect(day[:company_amount].to_d).to eq(expected_day_orders.sum { |o| o.price - o.discounted_price })
      end

      # 8. Coherencia y orden del consumo por proveedor (ordenado por viandas desc)
      meals_list = report.by_provider.map(&:meals)
      expect(meals_list).to eq(meals_list.sort.reverse)

      # Verificación puntual proveedor por proveedor
      confirmed_by_provider = confirmed_orders.group_by(&:provider_id)
      expect(report.by_provider.size).to eq(3)
      report.by_provider.each do |prov|
        expected_prov_orders = confirmed_by_provider[prov.provider_id]
        expect(prov.orders_count).to eq(expected_prov_orders.size)
        expect(prov.meals).to eq(expected_prov_orders.sum(&:amount))
        expect(prov.company_amount).to eq(expected_prov_orders.sum { |o| o.price - o.discounted_price })
      end

      # 9. Coherencia de modalidades de entrega
      home_orders = confirmed_orders.select(&:home?)
      office_orders = confirmed_orders.select(&:office?)

      expect(report.delivery_methods[:home][:orders]).to eq(home_orders.size)
      expect(report.delivery_methods[:home][:meals]).to eq(home_orders.sum(&:amount))
      expect(report.delivery_methods[:office][:orders]).to eq(office_orders.size)
      expect(report.delivery_methods[:office][:meals]).to eq(office_orders.sum(&:amount))
    end
  end
end
