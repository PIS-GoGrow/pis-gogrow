# frozen_string_literal: true

require "rails_helper"

RSpec.describe OnboardingBenefit, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:onboarding_date) { Date.new(2025, 5, 10) }
  let(:consumer)        { double("Consumer", onboarding_date: onboarding_date) }
  let(:deadline_days)   { 5 }
  let(:rule)            { described_class.new(deadline_days: deadline_days, limit: 1) }

  describe "validaciones" do
    describe "deadline_days" do
      it "es requerido" do
        rule.deadline_days = nil
        rule.valid?
        expect(rule.errors[:deadline_days]).to be_present
      end

      it "debe ser mayor a 0" do
        [ 0, -1 ].each do |value|
          rule.deadline_days = value
          rule.valid?
          expect(rule.errors[:deadline_days]).to be_present
        end
      end

      it "debe ser menor o igual a 100" do
        rule.deadline_days = 101
        rule.valid?
        expect(rule.errors[:deadline_days]).to be_present
      end

      it "acepta los valores límite 1 y 100" do
        [ 1, 100 ].each do |value|
          rule.deadline_days = value
          rule.valid?
          expect(rule.errors[:deadline_days]).to be_empty
        end
      end
    end

    describe "limit" do
      it "es requerido" do
        rule.limit = nil
        rule.valid?
        expect(rule.errors[:limit]).to be_present
      end

      it "debe ser mayor a 0" do
        [ 0, -1 ].each do |value|
          rule.limit = value
          rule.valid?
          expect(rule.errors[:limit]).to be_present
        end
      end

      it "no tiene errores cuando es positivo" do
        rule.limit = 3
        rule.valid?
        expect(rule.errors[:limit]).to be_empty
      end
    end
  end

  describe "#applicable_to?" do
    context "con deadline_days = 5 y onboarding el 10/05/2025" do
      it "es true el día del onboarding" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 5, 10))).to be true
      end

      it "es true dentro del rango de tolerancia" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 5, 12))).to be true
      end

      it "es true el último día del rango (onboarding + deadline_days)" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 5, 15))).to be true
      end

      it "es false el día siguiente al último día del rango" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 5, 16))).to be false
      end

      it "es false el día anterior al onboarding" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 5, 9))).to be false
      end

      it "es false lejos del onboarding, antes y después" do
        expect(rule.applicable_to?(consumer, date: Date.new(2024, 5, 12))).to be false
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 11, 20))).to be false
      end
    end

    context "con distintos valores de deadline_days" do
      context "deadline_days = 1" do
        let(:deadline_days) { 1 }

        it "incluye el día del onboarding y el siguiente" do
          expect(rule.applicable_to?(consumer, date: Date.new(2025, 5, 10))).to be true
          expect(rule.applicable_to?(consumer, date: Date.new(2025, 5, 11))).to be true
          expect(rule.applicable_to?(consumer, date: Date.new(2025, 5, 12))).to be false
        end
      end

      context "deadline_days = 100" do
        let(:deadline_days) { 100 }

        it "incluye el día 100 y excluye el 101" do
          expect(rule.applicable_to?(consumer, date: onboarding_date + 100)).to be true
          expect(rule.applicable_to?(consumer, date: onboarding_date + 101)).to be false
        end
      end
    end

    context "el onboarding es una fecha absoluta (no se repite cada año)" do
      it "no se aplica en la misma fecha de otro año" do
        expect(rule.applicable_to?(consumer, date: Date.new(2026, 5, 10))).to be false
        expect(rule.applicable_to?(consumer, date: Date.new(2024, 5, 10))).to be false
      end
    end

    context "cuando el rango cruza el fin de año" do
      let(:onboarding_date) { Date.new(2025, 12, 28) }
      let(:deadline_days)   { 10 }

      it "es true a ambos lados del cambio de año" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 12, 31))).to be true
        expect(rule.applicable_to?(consumer, date: Date.new(2026, 1, 1))).to be true
      end

      it "respeta el último día (28/12 + 10 días = 07/01)" do
        expect(rule.applicable_to?(consumer, date: Date.new(2026, 1, 7))).to be true
        expect(rule.applicable_to?(consumer, date: Date.new(2026, 1, 8))).to be false
      end
    end

    context "cuando el rango atraviesa un 29/02" do
      let(:onboarding_date) { Date.new(2024, 2, 27) }
      let(:deadline_days)   { 5 }

      it "cuenta el 29/02 como un día más de la ventana" do
        expect(rule.applicable_to?(consumer, date: Date.new(2024, 2, 29))).to be true
        expect(rule.applicable_to?(consumer, date: Date.new(2024, 3, 3))).to be true
        expect(rule.applicable_to?(consumer, date: Date.new(2024, 3, 4))).to be false
      end
    end

    context "cuando el onboarding fue un 29/02" do
      let(:onboarding_date) { Date.new(2024, 2, 29) }

      it "es true ese día y dentro del rango" do
        expect(rule.applicable_to?(consumer, date: Date.new(2024, 2, 29))).to be true
        expect(rule.applicable_to?(consumer, date: Date.new(2024, 3, 5))).to be true
        expect(rule.applicable_to?(consumer, date: Date.new(2024, 3, 6))).to be false
      end
    end

    context "cuando el consumer no tiene onboarding_date" do
      let(:onboarding_date) { nil }

      it "es false" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 5, 10))).to be false
      end
    end

    context "cuando el consumer es nil" do
      it "es false" do
        expect(rule.applicable_to?(nil, date: Date.new(2025, 5, 10))).to be false
      end
    end

    context "sin pasar date (usa Date.current por defecto)" do
      it "es true si hoy está dentro del rango" do
        travel_to Date.new(2025, 5, 12) do
          expect(rule.applicable_to?(consumer)).to be true
        end
      end

      it "es false si hoy está fuera del rango" do
        travel_to Date.new(2025, 5, 16) do
          expect(rule.applicable_to?(consumer)).to be false
        end
      end
    end

    context "el límite no afecta a la aplicabilidad" do
      it "no depende de limit" do
        big = described_class.new(deadline_days: 5, limit: 50)
        expect(big.applicable_to?(consumer, date: Date.new(2025, 5, 10))).to be true
      end
    end
  end

  describe "#benefit_deadline" do
    it "es la fecha de ingreso más deadline_days" do
      expect(rule.benefit_deadline(consumer, date: Date.new(2025, 5, 12))).to eq(Date.new(2025, 5, 15))
    end

    context "cuando el consumer no tiene onboarding_date" do
      let(:onboarding_date) { nil }

      it "es nil" do
        expect(rule.benefit_deadline(consumer)).to be_nil
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
