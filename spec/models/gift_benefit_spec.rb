# frozen_string_literal: true

require "rails_helper"

RSpec.describe GiftBenefit, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:consumer)       { double("Consumer", birthday: Date.new(1990, 5, 10)) }
  let(:effective_from) { Date.new(2025, 12, 20) }
  let(:deadline_date)  { Date.new(2025, 12, 31) }
  let(:rule) do
    described_class.new(effective_from: effective_from, deadline_date: deadline_date, limit: 1)
  end

  describe "validaciones" do
    # Se chequea `errors[:attr]` y no `valid?` porque la regla no tiene
    # benefit_configuration en estos tests.
    def errors_on(record, attribute)
      record.valid?
      record.errors[attribute]
    end

    it "requiere effective_from" do
      rule.effective_from = nil
      expect(errors_on(rule, :effective_from)).to be_present
    end

    it "requiere deadline_date" do
      rule.deadline_date = nil
      expect(errors_on(rule, :deadline_date)).to be_present
    end

    it "requiere limit" do
      rule.limit = nil
      expect(errors_on(rule, :limit)).to be_present
    end

    it "no tiene errores en esos atributos cuando están todos presentes" do
      rule.valid?
      expect(rule.errors.attribute_names & %i[effective_from deadline_date limit]).to be_empty
    end
  end

  describe "#applicable_to?" do
    it "es true el primer día del rango (effective_from)" do
      expect(rule.applicable_to?(consumer, date: Date.new(2025, 12, 20))).to be true
    end

    it "es true en un día intermedio del rango" do
      expect(rule.applicable_to?(consumer, date: Date.new(2025, 12, 25))).to be true
    end

    it "es true el último día del rango (deadline_date)" do
      expect(rule.applicable_to?(consumer, date: Date.new(2025, 12, 31))).to be true
    end

    it "es false el día anterior a effective_from" do
      expect(rule.applicable_to?(consumer, date: Date.new(2025, 12, 19))).to be false
    end

    it "es false el día siguiente a deadline_date" do
      expect(rule.applicable_to?(consumer, date: Date.new(2026, 1, 1))).to be false
    end

    it "es false lejos del rango, antes y después" do
      expect(rule.applicable_to?(consumer, date: Date.new(2025, 1, 1))).to be false
      expect(rule.applicable_to?(consumer, date: Date.new(2027, 6, 15))).to be false
    end

    context "cuando el rango es de un solo día" do
      let(:effective_from) { Date.new(2025, 7, 1) }
      let(:deadline_date)  { Date.new(2025, 7, 1) }

      it "es true ese día" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 7, 1))).to be true
      end

      it "es false el día anterior y el siguiente" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 6, 30))).to be false
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 7, 2))).to be false
      end
    end

    context "cuando el rango cruza el fin de año" do
      let(:effective_from) { Date.new(2025, 12, 28) }
      let(:deadline_date)  { Date.new(2026, 1, 5) }

      it "es true a ambos lados del cambio de año" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 12, 31))).to be true
        expect(rule.applicable_to?(consumer, date: Date.new(2026, 1, 1))).to be true
      end

      it "respeta los extremos" do
        expect(rule.applicable_to?(consumer, date: Date.new(2025, 12, 27))).to be false
        expect(rule.applicable_to?(consumer, date: Date.new(2026, 1, 5))).to be true
        expect(rule.applicable_to?(consumer, date: Date.new(2026, 1, 6))).to be false
      end
    end

    context "cuando el rango atraviesa un 29/02" do
      let(:effective_from) { Date.new(2024, 2, 27) }
      let(:deadline_date)  { Date.new(2024, 3, 2) }

      it "incluye el 29/02 y respeta el último día" do
        expect(rule.applicable_to?(consumer, date: Date.new(2024, 2, 29))).to be true
        expect(rule.applicable_to?(consumer, date: Date.new(2024, 3, 2))).to be true
        expect(rule.applicable_to?(consumer, date: Date.new(2024, 3, 3))).to be false
      end
    end

    context "el año no influye (las fechas son absolutas, no anuales)" do
      it "no se aplica en la misma fecha de otro año" do
        expect(rule.applicable_to?(consumer, date: Date.new(2024, 12, 25))).to be false
        expect(rule.applicable_to?(consumer, date: Date.new(2026, 12, 25))).to be false
      end
    end

    context "independencia del consumer" do
      it "no depende del consumer" do
        other = double("Consumer", birthday: Date.new(2000, 1, 1))
        date  = Date.new(2025, 12, 25)

        expect(rule.applicable_to?(consumer, date: date)).to be true
        expect(rule.applicable_to?(other, date: date)).to be true
      end

      it "funciona con consumer nil" do
        expect(rule.applicable_to?(nil, date: Date.new(2025, 12, 25))).to be true
      end
    end

    context "sin pasar date (usa Date.current por defecto)" do
      it "es true si hoy está dentro del rango" do
        travel_to Date.new(2025, 12, 25) do
          expect(rule.applicable_to?(consumer)).to be true
        end
      end

      it "es false si hoy está antes o después del rango" do
        travel_to Date.new(2025, 12, 1) do
          expect(rule.applicable_to?(consumer)).to be false
        end
        travel_to Date.new(2026, 2, 1) do
          expect(rule.applicable_to?(consumer)).to be false
        end
      end
    end

    context "el límite no afecta a la aplicabilidad" do
      it "no depende de limit" do
        big = described_class.new(effective_from: effective_from, deadline_date: deadline_date, limit: 50)
        expect(big.applicable_to?(consumer, date: Date.new(2025, 12, 25))).to be true
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
