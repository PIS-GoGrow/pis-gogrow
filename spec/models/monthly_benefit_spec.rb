# frozen_string_literal: true

# spec/models/monthly_benefit_spec.rb
require "rails_helper"

RSpec.describe MonthlyBenefit, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  fixtures :users

  let(:today)    { Date.new(2025, 6, 15) }
  let(:company)  { create(:company) }
  let(:consumer) { double("Consumer") }

  around { |example| travel_to(today) { example.run } }

  # Cada MonthlyBenefit necesita su propia configuración: no puede
  # coexistir con ninguna otra regla, ni siquiera otra Monthly.
  def create_configuration(company: self.company)
    create(:benefit_configuration, company: company, created_by: users(:admin))
  end

  let(:configuration) { create_configuration }

  def build_rule(effective_from:, configuration: self.configuration, **attrs)
    described_class.new(
      { benefit_configuration: configuration, max_price: 1000, limit: 1,
        effective_from: effective_from }.merge(attrs)
    )
  end

  # Saltea validaciones: permite crear reglas con effective_from en el pasado.
  # Por defecto usa una configuración nueva para no chocar con la exclusividad.
  def create_rule(effective_from:, configuration: create_configuration, **attrs)
    build_rule(effective_from: effective_from, configuration: configuration, **attrs)
      .tap { |r| r.save!(validate: false) }
  end

  def create_other_rule(configuration)
    BirthdayBenefit.new(benefit_configuration: configuration, deadline_days: 5, limit: 1)
      .tap { |r| r.save!(validate: false) }
  end

  describe "validaciones" do
    let(:rule) { build_rule(effective_from: today + 1) }

    it "es válida con atributos correctos" do
      expect(rule).to be_valid
    end

    describe "max_price" do
      it "es requerido" do
        rule.max_price = nil
        expect(rule).not_to be_valid
        expect(rule.errors[:max_price]).to be_present
      end

      it "debe ser mayor a 0" do
        [ 0, -1 ].each do |value|
          rule.max_price = value
          expect(rule).not_to be_valid
          expect(rule.errors[:max_price]).to be_present
        end
      end

      it "acepta decimales positivos" do
        rule.max_price = 1234.5
        expect(rule).to be_valid
      end
    end

    describe "limit" do
      it "es requerido" do
        rule.limit = nil
        expect(rule).not_to be_valid
        expect(rule.errors[:limit]).to be_present
      end

      it "debe ser mayor a 0" do
        [ 0, -3 ].each do |value|
          rule.limit = value
          expect(rule).not_to be_valid
          expect(rule.errors[:limit]).to be_present
        end
      end

      it "debe ser entero" do
        rule.limit = 1.5
        expect(rule).not_to be_valid
        expect(rule.errors[:limit]).to be_present
      end
    end

    describe "effective_from" do
      it "es requerido" do
        rule.effective_from = nil
        expect(rule).not_to be_valid
        expect(rule.errors[:effective_from]).to be_present
      end

      it "puede ser hoy" do
        rule.effective_from = today
        expect(rule).to be_valid
      end

      it "puede ser una fecha futura" do
        rule.effective_from = today + 30
        expect(rule).to be_valid
      end

      it "no puede ser una fecha pasada" do
        rule.effective_from = today - 1
        expect(rule).not_to be_valid
        expect(rule.errors[:effective_from]).to be_present
      end
    end

    describe "exclusividad dentro de la BenefitConfiguration" do
      it "es inválida si la configuración ya tiene otra MonthlyBenefit" do
        create_rule(effective_from: today + 10, configuration: configuration)

        second = build_rule(effective_from: today + 20, configuration: configuration)
        expect(second).not_to be_valid
        expect(second.errors).to be_present
      end

      it "es inválida si la configuración ya tiene una regla de otro tipo" do
        create_other_rule(configuration)

        expect(rule).not_to be_valid
        expect(rule.errors).to be_present
      end

      it "es válida en una configuración sin reglas" do
        expect(build_rule(effective_from: today + 10, configuration: create_configuration)).to be_valid
      end

      it "es válida en otra configuración aunque la primera ya tenga reglas" do
        create_other_rule(configuration)
        other_config = create_configuration

        expect(build_rule(effective_from: today + 10, configuration: other_config)).to be_valid
      end

      it "una regla ya guardada no choca consigo misma al actualizarse" do
        existing = create_rule(effective_from: today + 10, configuration: configuration)
        existing.max_price = 2000

        expect(existing).to be_valid
      end
    end

    describe "unicidad de effective_from por compañía" do
      let(:date) { today + 10 }

      before { create_rule(effective_from: date) }

      it "es inválida si la compañía ya tiene un MonthlyBenefit con esa fecha" do
        duplicate = build_rule(effective_from: date)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:effective_from]).to be_present
      end

      it "es inválida aunque esté en otra configuración de la misma compañía" do
        duplicate = build_rule(effective_from: date, configuration: create_configuration)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:effective_from]).to be_present
      end

      it "es válida con otra fecha en la misma compañía" do
        expect(build_rule(effective_from: date + 1)).to be_valid
      end

      it "es válida con la misma fecha en otra compañía" do
        other_config = create_configuration(company: create(:company))
        expect(build_rule(effective_from: date, configuration: other_config)).to be_valid
      end

      it "permite actualizar la regla existente sin que choque consigo misma" do
        existing = described_class.find_by!(effective_from: date)
        existing.max_price = 2000
        expect(existing).to be_valid
      end
    end
  end

  describe "#applicable_to?" do
    context "con una única regla en la compañía" do
      let!(:rule) { create_rule(effective_from: Date.new(2025, 3, 1)) }

      it "es true después de effective_from" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 6, 15))).to be true
      end

      it "es true el mismo día de effective_from" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 3, 1))).to be true
      end

      it "es false el día anterior a effective_from" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 2, 28))).to be false
      end

      it "es true mucho tiempo después (no tiene fecha de fin)" do
        expect(rule.applicable_to?(consumer, date: Date.new(2040, 1, 1))).to be true
      end
    end

    context "con otra regla de la compañía que entra en vigencia más tarde" do
      let!(:old_rule) { create_rule(effective_from: Date.new(2025, 1, 1)) }
      let!(:new_rule) { create_rule(effective_from: Date.new(2025, 7, 1)) }

      it "la vieja es true antes de que arranque la nueva" do
        expect(old_rule.applicable_to?(consumer, date: Date.new(2025, 6, 30))).to be true
      end

      it "la vieja es false el mismo día que arranca la nueva" do
        expect(old_rule.applicable_to?(consumer, date: Date.new(2025, 7, 1))).to be false
      end

      it "la vieja es false después de que arranca la nueva" do
        expect(old_rule.applicable_to?(consumer, date: Date.new(2025, 9, 1))).to be false
      end

      it "la nueva es false antes de su effective_from" do
        expect(new_rule.applicable_to?(consumer, date: Date.new(2025, 6, 30))).to be false
      end

      it "la nueva es true desde su effective_from" do
        expect(new_rule.applicable_to?(consumer, date: Date.new(2025, 7, 1))).to be true
        expect(new_rule.applicable_to?(consumer, date: Date.new(2026, 1, 1))).to be true
      end
    end

    context "con varias reglas sucesivas" do
      let!(:first)  { create_rule(effective_from: Date.new(2025, 1, 1)) }
      let!(:second) { create_rule(effective_from: Date.new(2025, 4, 1)) }
      let!(:third)  { create_rule(effective_from: Date.new(2025, 8, 1)) }

      it "solo una es aplicable en cada fecha" do
        {
          Date.new(2025, 2, 1)  => first,
          Date.new(2025, 4, 1)  => second,
          Date.new(2025, 7, 31) => second,
          Date.new(2025, 8, 1)  => third,
          Date.new(2026, 1, 1)  => third
        }.each do |date, expected|
          applicable = [ first, second, third ].select { |r| r.applicable_to?(consumer, date: date) }
          expect(applicable).to eq([ expected ]), "en #{date} se esperaba #{expected.effective_from}"
        end
      end

      it "ninguna es aplicable antes de la primera" do
        [ first, second, third ].each do |r|
          expect(r.applicable_to?(consumer, date: Date.new(2024, 12, 31))).to be false
        end
      end
    end

    context "con una regla posterior de otra compañía" do
      let!(:rule) { create_rule(effective_from: Date.new(2025, 1, 1)) }

      before do
        other_config = create_configuration(company: create(:company))
        create_rule(effective_from: Date.new(2025, 7, 1), configuration: other_config)
      end

      it "no afecta a esta regla" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 9, 1))).to be true
      end
    end

    context "con una regla posterior que todavía no arrancó en `date`" do
      let!(:rule)  { create_rule(effective_from: Date.new(2025, 1, 1)) }
      let!(:later) { create_rule(effective_from: Date.new(2026, 1, 1)) }

      it "sigue siendo true hasta el día anterior a la posterior" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 12, 31))).to be true
        expect(rule.applicable_to?(consumer, date: Date.new(2026, 1, 1))).to be false
      end
    end

    context "el consumer no influye" do
      let!(:rule) { create_rule(effective_from: Date.new(2025, 3, 1)) }

      it "funciona con cualquier consumer, incluso nil" do
        expect(rule.applicable_to?(nil, date: Date.new(2025, 6, 15))).to be true
        expect(rule.applicable_to?(double("Other"), date: Date.new(2025, 6, 15))).to be true
      end
    end

    context "sin pasar date (usa Date.current por defecto)" do
      let!(:rule) { create_rule(effective_from: Date.new(2025, 6, 15)) }

      it "es true si hoy es effective_from" do
        expect(rule.applicable_to?(consumer)).to be true
      end

      it "es false si hoy es anterior a effective_from" do
        travel_to(Date.new(2025, 6, 14))
        expect(rule.applicable_to?(consumer)).to be false
        travel_back
      end

      it "es false si hoy ya rige una regla posterior" do
        create_rule(effective_from: Date.new(2025, 6, 20))
        travel_to(Date.new(2025, 6, 20))
        expect(rule.applicable_to?(consumer)).to be false
        travel_back
      end
    end
  end
end
# == Schema Information
#
# Table name: benefit_rules
#
#  id                       :bigint           not null, primary key
#  deadline_date            :date
#  deadline_days            :integer
#  effective_from           :date
#  limit                    :integer
#  max_price                :decimal(10, 2)
#  min_years                :integer
#  type                     :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  benefit_configuration_id :bigint           not null
#
# Indexes
#
#  index_benefit_rules_on_benefit_configuration_id  (benefit_configuration_id)
#
# Foreign Keys
#
#  fk_rails_...  (benefit_configuration_id => benefit_configurations.id)
#
