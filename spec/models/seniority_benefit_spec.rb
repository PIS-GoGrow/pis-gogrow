# frozen_string_literal: true

require "rails_helper"

RSpec.describe SeniorityBenefit, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:onboarding_date) { Date.new(2020, 3, 15) }
  let(:consumer)  { double("Consumer", onboarding_date: onboarding_date) }
  let(:min_years) { 2 }
  let(:rule)      { described_class.new(min_years: min_years, limit: 1) }

  describe "validaciones" do
    it "requiere min_years" do
      rule.min_years = nil
      rule.valid?
      expect(rule.errors[:min_years]).to be_present
    end

    it "no tiene errores en min_years cuando está presente" do
      rule.valid?
      expect(rule.errors[:min_years]).to be_empty
    end
  end

  describe "#applicable_to?" do
    context "con min_years = 2 e ingreso el 15/03/2020" do
      it "es false el día del ingreso" do
        expect(rule.applicable_to?(consumer, date: Date.new(2020, 3, 15))).to be false
      end

      it "es false antes de cumplir los años requeridos" do
        expect(rule.applicable_to?(consumer, date: Date.new(2021, 6, 1))).to be false
      end

      it "es false el día anterior al aniversario" do
        expect(rule.applicable_to?(consumer, date: Date.new(2022, 3, 14))).to be false
      end

      it "es true el día exacto en que cumple min_years" do
        expect(rule.applicable_to?(consumer, date: Date.new(2022, 3, 15))).to be true
      end

      it "es true al día siguiente del aniversario" do
        expect(rule.applicable_to?(consumer, date: Date.new(2022, 3, 16))).to be true
      end

      it "sigue siendo true mucho tiempo después (no hay fecha de fin)" do
        expect(rule.applicable_to?(consumer, date: Date.new(2030, 1, 1))).to be true
        expect(rule.applicable_to?(consumer, date: Date.new(2050, 12, 31))).to be true
      end

      it "es false si la fecha es anterior al ingreso" do
        expect(rule.applicable_to?(consumer, date: Date.new(2019, 1, 1))).to be false
      end
    end

    context "con distintos valores de min_years" do
      context "min_years = 1" do
        let(:min_years) { 1 }

        it "aplica desde el primer aniversario" do
          expect(rule.applicable_to?(consumer, date: Date.new(2021, 3, 14))).to be false
          expect(rule.applicable_to?(consumer, date: Date.new(2021, 3, 15))).to be true
        end
      end

      context "min_years = 10" do
        let(:min_years) { 10 }

        it "aplica desde el décimo aniversario" do
          expect(rule.applicable_to?(consumer, date: Date.new(2030, 3, 14))).to be false
          expect(rule.applicable_to?(consumer, date: Date.new(2030, 3, 15))).to be true
        end
      end

      context "min_years = 0" do
        let(:min_years) { 0 }

        it "aplica desde el día del ingreso" do
          expect(rule.applicable_to?(consumer, date: Date.new(2020, 3, 14))).to be false
          expect(rule.applicable_to?(consumer, date: Date.new(2020, 3, 15))).to be true
        end
      end
    end

    context "cuando el ingreso fue el 29 de febrero" do
      let(:onboarding_date) { Date.new(2020, 2, 29) }
      let(:min_years) { 1 }

      it "en año no bisiesto, el aniversario se toma como 28/02" do
        expect(rule.applicable_to?(consumer, date: Date.new(2021, 2, 27))).to be false
        expect(rule.applicable_to?(consumer, date: Date.new(2021, 2, 28))).to be true
      end

      context "con min_years = 4" do
        let(:min_years) { 4 }

        it "en año bisiesto, el aniversario es el 29/02" do
          expect(rule.applicable_to?(consumer, date: Date.new(2024, 2, 28))).to be false
          expect(rule.applicable_to?(consumer, date: Date.new(2024, 2, 29))).to be true
        end
      end
    end

    context "cuando el aniversario cae el 31 de diciembre" do
      let(:onboarding_date) { Date.new(2020, 12, 31) }
      let(:min_years) { 1 }

      it "aplica el 31/12 y el 01/01 siguiente" do
        expect(rule.applicable_to?(consumer, date: Date.new(2021, 12, 30))).to be false
        expect(rule.applicable_to?(consumer, date: Date.new(2021, 12, 31))).to be true
        expect(rule.applicable_to?(consumer, date: Date.new(2022, 1, 1))).to be true
      end
    end

    context "cuando el consumer no tiene fecha de ingreso" do
      let(:onboarding_date) { nil }

      it "es false" do
        expect(rule.applicable_to?(consumer, date: Date.new(2030, 1, 1))).to be false
      end
    end

    context "cuando el consumer es nil" do
      it "es false" do
        expect(rule.applicable_to?(nil, date: Date.new(2030, 1, 1))).to be false
      end
    end

    context "sin pasar date (usa Date.current por defecto)" do
      it "es true si hoy ya cumplió los años requeridos" do
        travel_to Date.new(2022, 3, 15) do
          expect(rule.applicable_to?(consumer)).to be true
        end
      end

      it "es false si hoy todavía no los cumplió" do
        travel_to Date.new(2022, 3, 14) do
          expect(rule.applicable_to?(consumer)).to be false
        end
      end
    end

    context "el límite no afecta a la aplicabilidad" do
      it "no depende de limit" do
        big = described_class.new(min_years: 2, limit: 50)
        expect(big.applicable_to?(consumer, date: Date.new(2022, 3, 15))).to be true
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
