# frozen_string_literal: true

require "rails_helper"

RSpec.describe BirthdayBenefit, type: :model do
  let(:birthday)      { Date.new(1990, 5, 10) }
  let(:consumer)      { double("Consumer", birthday: birthday) }
  let(:deadline_days) { 5 }
  let(:rule)          { described_class.new(deadline_days: deadline_days, limit: 1) }

  describe "#applicable_to?" do
    context "en el año corriente, con deadline_days = 5 y cumpleaños el 10/05" do
      it "es true el día del cumpleaños" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 5, 10))).to be true
      end

      it "es true dentro del rango de tolerancia" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 5, 12))).to be true
      end

      it "es true el último día del rango (cumpleaños + deadline_days)" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 5, 15))).to be true
      end

      it "es false el día siguiente al último día del rango" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 5, 16))).to be false
      end

      it "es false el día anterior al cumpleaños" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 5, 9))).to be false
      end

      it "es false lejos del cumpleaños" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 11, 20))).to be false
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 1, 1))).to be false
      end
    end

    context "con distintos valores de deadline_days" do
      let(:deadline_days) { 1 }

      it "con deadline_days = 1 incluye el cumpleaños y el día siguiente" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 5, 10))).to be true
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 5, 11))).to be true
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 5, 12))).to be false
      end

      context "con deadline_days = 100" do
        let(:deadline_days) { 100 }

        it "incluye el día 100 y excluye el 101" do
          expect(rule.applicable_to?(consumer, date: birthday_in(2025) + 100)).to be true
          expect(rule.applicable_to?(consumer, date: birthday_in(2025) + 101)).to be false
        end
      end
    end

    context "el año de nacimiento no influye" do
      it "da el mismo resultado sin importar el año de nacimiento" do
        young = double("Consumer", birthday: Date.new(2005, 5, 10))
        old   = double("Consumer", birthday: Date.new(1950, 5, 10))
        date  = Date.new(2025, 5, 13)

        expect(rule.applicable_to?(young, date: date)).to be true
        expect(rule.applicable_to?(old, date: date)).to be true
      end

      it "es true el día del cumpleaños del año en que nació (cumpleaños 0)" do
        newborn = double("Consumer", birthday: Date.new(2025, 5, 10))
        expect(rule.applicable_to?(newborn, date: Date.new(2025, 5, 10))).to be true
      end
    end

    context "cuando el rango cruza el fin de año" do
      let(:birthday)      { Date.new(1990, 12, 28) }
      let(:deadline_days) { 10 }

      it "es true en diciembre, después del cumpleaños" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 12, 31))).to be true
      end

      it "es true en enero del año siguiente, dentro del rango" do
        expect(rule.applicable_to?(consumer, date: Date.new(2026, 1, 1))).to be true
        expect(rule.applicable_to?(consumer, date: Date.new(2026, 1, 7))).to be true
      end

      it "es false en enero del año siguiente, fuera del rango" do
        # 28/12 + 10 días = 07/01
        expect(rule.applicable_to?(consumer, date: Date.new(2026, 1, 8))).to be false
      end

      it "es false a principios de enero si todavía no llegó el cumpleaños de ese año... y ya pasó el rango del anterior" do
        expect(rule.applicable_to?(consumer, date: Date.new(2026, 6, 1))).to be false
      end
    end

    context "cumpleaños el 29 de febrero" do
      let(:birthday) { Date.new(1992, 2, 29) }

      it "es true el 29/02 en un año bisiesto" do
        expect(rule.applicable_to?(consumer, date: Date.new(2024, 2, 29))).to be true
      end

      it "no lanza error en un año no bisiesto" do
        expect { rule.applicable_to?(consumer, date: Date.new(2025, 3, 1)) }.not_to raise_error
      end

      it "es true el 01/03 en un año no bisiesto (dentro del rango con cualquier convención)" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 3, 1))).to be true
      end

      it "es false bastante después del rango en un año no bisiesto" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 3, 15))).to be false
      end
    end

    context "cuando el consumidor no tiene cumpleaños" do
      let(:birthday) { nil }

      it "es false" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 5, 10))).to be false
      end
    end

    context "sin pasar date (usa Date.current por defecto)" do
      include ActiveSupport::Testing::TimeHelpers

      it "es true si hoy es el cumpleaños" do
        travel_to Date.new(2025, 5, 10) do
          expect(rule.applicable_to?(consumer)).to be true
        end
      end

      it "es false si hoy está fuera del rango" do
        travel_to Date.new(2025, 8, 1) do
          expect(rule.applicable_to?(consumer)).to be false
        end
      end
    end

    context "el límite no afecta a la aplicabilidad" do
      it "no depende de limit" do
        rule_with_big_limit = described_class.new(deadline_days: 5, limit: 50)
        expect(rule_with_big_limit.applicable_to?(consumer, date: Date.new(2025, 5, 10))).to be true
      end
    end
  end

  describe "#benefit_deadline" do
    it "es el cumpleaños del año más deadline_days" do
      expect(rule.benefit_deadline(consumer, date: Date.new(2025, 5, 12))).to eq(Date.new(2025, 5, 15))
    end

    context "cuando el rango cruza el fin de año" do
      let(:birthday)      { Date.new(1990, 12, 28) }
      let(:deadline_days) { 10 }

      it "vence en enero del año siguiente si hoy es diciembre" do
        expect(rule.benefit_deadline(consumer, date: Date.new(2025, 12, 30))).to eq(Date.new(2026, 1, 7))
      end

      it "vence en enero del mismo año si hoy ya es enero" do
        expect(rule.benefit_deadline(consumer, date: Date.new(2026, 1, 3))).to eq(Date.new(2026, 1, 7))
      end
    end

    it "es nil fuera del rango" do
      expect(rule.benefit_deadline(consumer, date: Date.new(2025, 8, 1))).to be_nil
    end

    it "es nil cuando el consumidor no tiene cumpleaños" do
      expect(rule.benefit_deadline(double("Consumer", birthday: nil), date: Date.new(2025, 5, 10))).to be_nil
    end
  end

  def birthday_in(year)
    Date.new(year, birthday.month, birthday.day)
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
