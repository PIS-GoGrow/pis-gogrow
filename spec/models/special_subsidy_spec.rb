# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Subsidios especiales (BenefitConfiguration sin MonthlyBenefit)", type: :model do
  include ActiveSupport::Testing::TimeHelpers

  fixtures :users, :companies, :consumers, :benefit_configurations, :benefit_rules

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

    it "calcula la fecha límite del premio sumando la validez a la fecha de inicio" do
      configuration = save_special(condition: { type: "gift", limit: 3, effective_from: "2026-06-01", validity_amount: 1, validity_unit: "months" })

      rule = configuration.benefit_rules.first
      expect(rule).to be_a(GiftBenefit)
      expect(rule.deadline_date).to eq(Date.new(2026, 7, 1))
      expect(configuration.special_condition).to include(type: "gift", effective_from: Date.new(2026, 6, 1), validity_amount: 1, validity_unit: "months")
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
