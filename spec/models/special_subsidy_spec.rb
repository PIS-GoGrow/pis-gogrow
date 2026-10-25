# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Subsidios especiales (BenefitConfiguration sin MonthlyBenefit)", type: :model do
  include ActiveSupport::Testing::TimeHelpers

  fixtures :users, :companies, :consumers, :providers, :benefit_configurations, :benefit_rules

  let(:company) { companies(:gogrow) }
  let(:admin_user) { users(:admin) }
  let(:one) { consumers(:one) }
  let(:other) { consumers(:other) }

  around { |example| travel_to(Date.new(2026, 5, 12)) { example.run } }

  def save_special(configuration = company.benefit_configurations.new(created_by: admin_user), **attrs)
    configuration.save_special_subsidy(
      by: admin_user,
      **{
        name: "Cumpleaños",
        subsidy_percentage: 25,
        applies_to_all: true,
        consumer_ids: [],
        condition: { type: "birthday", limit: 1, validity_amount: 1, validity_unit: "weeks" }
      }.merge(attrs)
    )
    configuration
  end

  describe "#save_special_subsidy" do
    it "crea la configuración con una sola regla y sin MonthlyBenefit" do
      configuration = save_special

      expect(configuration).to be_persisted
      expect(configuration.benefit_rules.map(&:class)).to eq([ BirthdayBenefit ])
      expect(configuration.benefit_rules.first.deadline_days).to eq(7)
      expect(BenefitConfiguration.special).to include(configuration)
      expect(BenefitConfiguration.special).not_to include(benefit_configurations(:monthly))
    end

    it "convierte la validez en meses a días (30 por mes)" do
      configuration = save_special(condition: { type: "onboarding", limit: 2, validity_amount: 3, validity_unit: "months" })

      expect(configuration.benefit_rules.first.deadline_days).to eq(90)
      expect(configuration.special_condition).to include(validity_amount: 3, validity_unit: "months")
    end

    it "rechaza una validez de más de 100 días" do
      configuration = save_special(condition: { type: "birthday", limit: 1, validity_amount: 4, validity_unit: "months" })

      expect(configuration).not_to be_persisted
      expect(configuration.benefit_rules.first.errors[:deadline_days]).to be_present
    end

    it "calcula la fecha límite del cupón como el último día de la validez" do
      configuration = save_special(condition: { type: "gift", limit: 3, effective_from: "2026-06-01", validity_amount: 1, validity_unit: "months" })

      rule = configuration.benefit_rules.first
      expect(rule).to be_a(GiftBenefit)
      expect(rule.deadline_date).to eq(Date.new(2026, 6, 30))
      expect(configuration.special_condition).to include(type: "gift", effective_from: Date.new(2026, 6, 1), validity_amount: 1, validity_unit: "months")
    end

    it "da un cupón de una semana que se usa siete días" do
      configuration = save_special(condition: { type: "gift", limit: 3, effective_from: "2026-05-18", validity_amount: 1, validity_unit: "weeks" })

      expect(configuration.benefit_rules.first.deadline_date).to eq(Date.new(2026, 5, 24))
      expect(configuration.special_condition).to include(validity_amount: 1, validity_unit: "weeks")
    end

    it "acepta un cupón de un solo día" do
      configuration = save_special(condition: { type: "gift", limit: 1, effective_from: "2026-05-12", validity_amount: 1, validity_unit: "days" })

      expect(configuration).to be_persisted
      expect(configuration.benefit_rules.first.deadline_date).to eq(Date.new(2026, 5, 12))
      expect(configuration.special_condition).to include(validity_amount: 1, validity_unit: "days")
      expect(one.benefits.find_by!(benefit_configuration: configuration).due_date).to eq(Date.new(2026, 5, 12))
    end

    it "rechaza un premio que empieza en el pasado" do
      configuration = save_special(condition: { type: "gift", limit: 3, effective_from: "2026-05-01", validity_amount: 2, validity_unit: "days" })

      expect(configuration).not_to be_persisted
      expect(configuration.benefit_rules.first.errors[:effective_from]).to be_present
    end

    it "exige nombre, porcentaje entre 1 y 100 y una condición" do
      configuration = save_special(name: "", subsidy_percentage: 0, condition: {})

      expect(configuration).not_to be_persisted
      expect(configuration.errors.attribute_names).to include(:name, :subsidy_percentage, :condition_type)
    end

    it "exige al menos un empleado cuando no aplica a todos" do
      configuration = save_special(applies_to_all: false, consumer_ids: [])

      expect(configuration.errors[:consumers]).to be_present
    end

    it "rechaza empleados de otra compañía" do
      other_company = Company.create!(name: "Otra", address: "Calle 1")
      stranger = Consumer.create!(company: other_company, user: users(:two))

      configuration = save_special(applies_to_all: false, consumer_ids: [ stranger.id ])

      expect(configuration).not_to be_persisted
      expect(configuration.errors[:consumers]).to be_present
    end

    it "audita la creación con quién la hizo y cómo quedó" do
      configuration = save_special(applies_to_all: false, consumer_ids: [ one.id ])

      change = configuration.benefit_configuration_changes.sole
      expect(change).to be_created
      expect(change.user).to eq(admin_user)
      expect(change.details).to include("name" => "Cumpleaños", "consumer_ids" => [ one.id ])
    end
  end

  describe "asignación de beneficios" do
    it "asigna el beneficio solo a quien cumple la condición, dentro de su vigencia" do
      configuration = save_special

      benefit = one.benefits.find_by!(benefit_configuration: configuration)
      expect(benefit).to have_attributes(percentage: 25, amount: 1, due_date: Date.new(2026, 5, 17), status: "current")
      expect(other.benefits.where(benefit_configuration: configuration)).to be_empty
    end

    it "con una selección solo alcanza a los empleados elegidos" do
      configuration = save_special(name: "Antigüedad", applies_to_all: false, consumer_ids: [ other.id ], condition: { type: "seniority", min_years: 1 })

      expect(configuration.benefits).to be_empty

      travel_to Date.new(2026, 8, 15)
      configuration.apply_to_all_consumers
      expect(configuration.benefits.map(&:consumer)).to eq([ other ])
    end

    it "con applies_to_all incluye a los empleados que entran después" do
      configuration = save_special(name: "Antigüedad", condition: { type: "seniority", min_years: 1 })
      newcomer = Consumer.create!(company:, user: users(:two), onboarding_date: Date.new(2020, 1, 1))

      configuration.apply_to_all_consumers

      expect(configuration.benefits.map(&:consumer)).to include(newcomer)
    end
  end

  describe "edición" do
    it "actualiza los beneficios vigentes sin duplicarlos" do
      configuration = save_special
      benefit = one.benefits.find_by!(benefit_configuration: configuration)

      save_special(configuration, subsidy_percentage: 40, condition: { type: "birthday", limit: 2, validity_amount: 10, validity_unit: "days" })

      expect(configuration.benefits.current.count).to eq(1)
      expect(benefit.reload).to have_attributes(percentage: 40, amount: 2, due_date: Date.new(2026, 5, 20))
      expect(configuration.benefit_configuration_changes.map(&:action)).to eq(%w[created updated])
    end

    it "vence el beneficio de quien deja de estar incluido" do
      configuration = save_special
      benefit = one.benefits.find_by!(benefit_configuration: configuration)

      save_special(configuration, applies_to_all: false, consumer_ids: [ other.id ])

      expect(benefit.reload).to be_expired
    end

    it "reemplaza la regla si cambia el tipo de condición" do
      configuration = save_special

      save_special(configuration, condition: { type: "seniority", min_years: 2 })

      expect(configuration.reload.benefit_rules.map(&:class)).to eq([ SeniorityBenefit ])
    end

    it "no guarda nada si la edición es inválida" do
      configuration = save_special

      expect(configuration.save_special_subsidy(by: admin_user, name: "", subsidy_percentage: 25, applies_to_all: false, consumer_ids: [], condition: { type: "seniority", min_years: 2 })).to be false

      configuration.reload
      expect(configuration).to have_attributes(name: "Cumpleaños", applies_to_all: true)
      expect(configuration.benefit_rules.map(&:class)).to eq([ BirthdayBenefit ])
    end
  end

  describe "cupones" do
    def save_coupon(configuration = company.benefit_configurations.new(created_by: admin_user), effective_from: "2026-05-12", **attrs)
      save_special(
        configuration,
        name: "Cupón",
        subsidy_percentage: 30,
        applies_to_all: false,
        consumer_ids: [ one.id ],
        condition: { type: "gift", limit: 3, effective_from:, validity_amount: 1, validity_unit: "weeks" },
        **attrs
      )
    end

    it "se asigna al guardarlo solo a los empleados elegidos, con su porcentaje y su cantidad de platos" do
      configuration = save_coupon

      expect(one.benefits.find_by!(benefit_configuration: configuration))
        .to have_attributes(percentage: 30, amount: 3, due_date: Date.new(2026, 5, 18), status: "current", description: "Cupón")
      expect(other.benefits.where(benefit_configuration: configuration)).to be_empty
    end

    it "si empieza más adelante, no se asigna antes y lo asigna el job el día de inicio" do
      configuration = save_coupon(effective_from: "2026-05-13")

      expect(configuration.benefits).to be_empty

      travel_to Date.new(2026, 5, 13)
      BenefitAssignationJob.perform_now

      expect(configuration.benefits.sole).to have_attributes(consumer: one, due_date: Date.new(2026, 5, 19), status: "current")
    end

    it "al sacar a un empleado de la lista le vence el cupón y los demás lo conservan" do
      configuration = save_coupon(consumer_ids: [ one.id, other.id ])
      benefit_one = one.benefits.find_by!(benefit_configuration: configuration)
      benefit_other = other.benefits.find_by!(benefit_configuration: configuration)

      save_coupon(configuration, consumer_ids: [ other.id ])

      expect(benefit_one.reload).to be_expired
      expect(benefit_other.reload).to be_current
      expect(one.special_benefits).not_to include(benefit_one)
    end

    it "al sacarlo, los pedidos ya hechos conservan el descuento y los nuevos no lo reciben" do
      configuration = save_coupon(consumer_ids: [ one.id, other.id ])
      benefit = one.benefits.find_by!(benefit_configuration: configuration)
      menu = Menu.create!(provider: providers(:tuviandita), name: "Milanesa al pan", description: "Con papas", price: 300)
      today, tomorrow = [ Date.current, Date.tomorrow ].map { Schedule.create!(menu:, date: it, amount: 10) }
      orders = [ today, tomorrow ].map do |schedule|
        Order.reserve(consumer: one, schedule:, delivery_method: :office, address: nil, discounted_price: 210, benefits: { benefit => 1 })
      end
      orders.first.update!(status: :confirmed)

      save_coupon(configuration, consumer_ids: [ other.id ])

      orders.each { expect(it.reload).to have_attributes(discounted_price: 210, benefits: [ benefit ]) }
      expect(OrderPricing.new(one).call([ { schedule: tomorrow, quantity: 1 } ])[tomorrow.id].benefits).not_to have_key(benefit)

      configuration.deactivate!(by: admin_user)

      orders.each { expect(it.reload.discounted_price).to eq(210) }
    end

    it "al eliminarlo vence para todos y no se vuelve a asignar" do
      configuration = save_coupon(consumer_ids: [ one.id, other.id ])

      configuration.deactivate!(by: admin_user)
      BenefitAssignationJob.perform_now

      expect(configuration.benefits.current).to be_empty
      expect(configuration.benefits.map(&:consumer)).to contain_exactly(one, other)
    end

    it "para toda la empresa les llega a todos sus empleados y a nadie de otra empresa" do
      stranger = Consumer.create!(company: Company.create!(name: "Otra", address: "Calle 1"), user: users(:two))

      configuration = save_coupon(applies_to_all: true, consumer_ids: [])

      expect(configuration.benefits.map(&:consumer)).to match_array(company.consumers)
      expect(stranger.benefits).to be_empty
    end
  end

  describe "#deactivate!" do
    it "vence los beneficios, conserva el historial y deja de asignar" do
      configuration = save_special
      benefit = one.benefits.find_by!(benefit_configuration: configuration)

      configuration.deactivate!(by: admin_user)
      configuration.apply_to_all_consumers

      expect(benefit.reload).to be_expired
      expect(configuration.benefits.current).to be_empty
      expect(BenefitConfiguration.active).not_to include(configuration)
      expect(configuration.benefit_configuration_changes.last).to be_deactivated
    end
  end
end
