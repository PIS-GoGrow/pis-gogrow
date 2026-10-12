# frozen_string_literal: true

require "rails_helper"

RSpec.describe Benefit, type: :model do
  fixtures :consumers, :benefit_configurations, :benefits

  let(:consumer) { consumers(:one) }

  describe "associations" do
    it "belongs to a consumer" do
      benefit = described_class.new(consumer:, amount: 5, percentage: 50, due_date: 1.month.from_now)
      expect(benefit.consumer).to eq(consumer)
    end

    it "requires a consumer" do
      benefit = described_class.new(consumer: nil, amount: 5, percentage: 50, due_date: 1.month.from_now)
      expect(benefit).not_to be_valid
    end
  end

  describe ".expire_old!" do
    before do
      benefits(:monthly).destroy
    end

    it "expires old benefits" do
      expired1 = described_class.create!(consumer:, amount: 5, status: :current, percentage: 50, due_date: Date.current - 2.days, benefit_configuration: benefit_configurations(:monthly))
      expired2 = described_class.create!(consumer:, amount: 5, status: :current, percentage: 50, due_date: Date.current - 3.days, benefit_configuration: benefit_configurations(:gift))

      Benefit.expire_old! Date.current

      expect(expired1.reload.status).to eq("expired")
      expect(expired2.reload.status).to eq("expired")
    end

    it "preserves current benefits" do
      current1 = described_class.create!(consumer:, amount: 5, status: :current, percentage: 50, due_date: Date.current, benefit_configuration: benefit_configurations(:monthly))
      current2 = described_class.create!(consumer:, amount: 5, status: :current, percentage: 50, due_date: Date.current + 3.days, benefit_configuration: benefit_configurations(:gift))

      Benefit.expire_old! Date.current

      expect(current1.reload.status).to eq("current")
      expect(current2.reload.status).to eq("current")
    end
  end

  describe ".make_current!" do
    fixtures :consumers, :benefit_configurations, :benefits

    # Supuestos: `date` es cualquier día del mes cuyos beneficios future se activan
    # (se filtran por due_date dentro de ese mes), y los fixtures :one y :two
    # existen en consumers y benefit_configurations. Ajustá nombres y filtro si difieren.
    let(:date) { Date.new(2026, 11, 1) }
    let(:consumer) { consumers(:one) }
    let(:other_consumer) { consumers(:other) }
    let(:configuration) { benefit_configurations(:monthly) }
    let(:other_configuration) { benefit_configurations(:gift) }

    before { Benefit.delete_all }

    def create_benefit(status:, due_date: date.end_of_month, consumer: self.consumer, configuration: self.configuration)
      Benefit.create!(
        consumer: consumer,
        benefit_configuration_id: configuration.id,
        status: status,
        due_date: due_date,
        amount: 1000,
        percentage: 50,
        description: "Beneficio de prueba"
      )
    end

    it "marca como current un beneficio future si no hay otro current con la misma configuración" do
      benefit = create_benefit(status: :future)

      Benefit.make_current!(date)

      expect(benefit.reload).to be_current
    end

    it "marca como current beneficios future de distintos consumidores" do
      first = create_benefit(status: :future, consumer: consumer)
      second = create_benefit(status: :future, consumer: other_consumer)

      Benefit.make_current!(date)

      expect(first.reload).to be_current
      expect(second.reload).to be_current
    end

    it "no marca como current un beneficio future si ya hay uno current con la misma configuración" do
      current = create_benefit(status: :current, due_date: date.prev_month.end_of_month)
      future = create_benefit(status: :future)

      Benefit.make_current!(date)

      expect(future.reload).to be_future
      expect(current.reload).to be_current
    end

    it "marca el future si el beneficio current de la misma configuración es de otro consumidor y la configuración es distinta" do
      create_benefit(status: :current, consumer: other_consumer, configuration: other_configuration)
      future = create_benefit(status: :future, consumer: consumer, configuration: configuration)

      Benefit.make_current!(date)

      expect(future.reload).to be_current
    end

    it "no marca como current un beneficio future si hay un current de la misma configuración, aunque haya otros future que sí se puedan marcar" do
      create_benefit(status: :current, due_date: date.prev_month.end_of_month)
      blocked = create_benefit(status: :future)
      allowed = create_benefit(status: :future, configuration: other_configuration)

      Benefit.make_current!(date)

      expect(blocked.reload).to be_future
      expect(allowed.reload).to be_current
    end

    it "no modifica los beneficios expired" do
      expired = create_benefit(status: :expired, due_date: date.prev_month.end_of_month)
      create_benefit(status: :future)

      Benefit.make_current!(date)

      expect(expired.reload).to be_expired
    end

    it "no modifica los beneficios que ya son current" do
      current = create_benefit(status: :current)

      expect { Benefit.make_current!(date) }.not_to(change { current.reload.attributes })
    end

    it "no hace nada si no hay beneficios future" do
      create_benefit(status: :current)
      create_benefit(status: :expired)

      expect { Benefit.make_current!(date) }.not_to(change { Benefit.order(:id).pluck(:id, :status) })
    end

    it "es idempotente" do
      benefit = create_benefit(status: :future)

      Benefit.make_current!(date)

      expect { Benefit.make_current!(date) }.not_to(change { benefit.reload.attributes })
    end
  end

  describe "scopes" do
    before do
      benefits(:monthly).destroy
    end

    it ".current includes benefits due today or in the future and excludes past ones" do
      active = described_class.create!(consumer:, status: :current, amount: 5, percentage: 50, due_date: nil, benefit_configuration: benefit_configurations(:seniority))
      today = described_class.create!(consumer:, status: :current, amount: 5, percentage: 50, due_date: Date.current, benefit_configuration: benefit_configurations(:gift))
      expired = described_class.create!(consumer:, status: :current, amount: 5, percentage: 50, due_date: Date.current - 1.day, benefit_configuration: benefit_configurations(:monthly))

      Benefit.expire_old! Date.current

      expect(described_class.current.reload).to include(active, today)
      expect(described_class.current.reload).not_to include(expired)
    end

    it ".monthly includes only benefits associated to a monthly benefit configuration" do
      monthly = described_class.create!(consumer:, amount: 20, percentage: 50, due_date: 1.month.from_now, description: "Viandas mensuales", benefit_configuration: benefit_configurations(:monthly))
      special = described_class.create!(consumer:, amount: 5, percentage: 100, due_date: 1.month.from_now, description: "Bono especial", benefit_configuration: benefit_configurations(:gift))

      expect(described_class.monthly).to include(monthly)
      expect(described_class.monthly).not_to include(special)
    end
  end

  describe "validations and business integrity" do
    before { Benefit.delete_all }

    it "permite tener un beneficio mensual 'current' y otro 'future' simultáneamente para el mismo consumidor" do
      described_class.create!(
        consumer:,
        benefit_configuration: benefit_configurations(:monthly),
        status: :current,
        percentage: 50,
        amount: 20,
        due_date: Date.current.end_of_month
      )

      future_benefit = described_class.new(
        consumer:,
        benefit_configuration: benefit_configurations(:monthly),
        status: :future,
        percentage: 60,
        amount: 15,
        due_date: Date.current.next_month.end_of_month
      )

      expect(future_benefit).to be_valid
      expect { future_benefit.save! }.not_to raise_error
      expect(Benefit.where(consumer:).count).to eq(2)
    end

    it "rechaza crear un segundo beneficio mensual 'current' para el mismo consumidor" do
      described_class.create!(
        consumer:,
        benefit_configuration: benefit_configurations(:monthly),
        status: :current,
        percentage: 50,
        amount: 20,
        due_date: Date.current.end_of_month
      )

      second_current = described_class.new(
        consumer:,
        benefit_configuration: benefit_configurations(:monthly),
        status: :current,
        percentage: 70,
        amount: 10,
        due_date: Date.current.next_month.end_of_month
      )

      expect(second_current).not_to be_valid
      expect(second_current.errors[:base]).to include("el cliente ya tiene un beneficio mensual")
    end

    it "rechaza un porcentaje negativo o mayor a 100" do
      invalid_low = described_class.new(
        consumer:,
        benefit_configuration: benefit_configurations(:monthly),
        status: :current,
        percentage: -5,
        due_date: Date.current.end_of_month
      )
      invalid_high = described_class.new(
        consumer:,
        benefit_configuration: benefit_configurations(:monthly),
        status: :current,
        percentage: 105,
        due_date: Date.current.end_of_month
      )

      expect(invalid_low).not_to be_valid
      expect(invalid_high).not_to be_valid
    end
  end
end

# == Schema Information
#
# Table name: benefits
#
#  id                       :bigint           not null, primary key
#  amount                   :integer
#  description              :string
#  due_date                 :date
#  max_price                :decimal(10, 2)
#  percentage               :integer
#  status                   :integer
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  benefit_configuration_id :bigint
#  consumer_id              :bigint           not null
#
# Indexes
#
#  index_benefits_on_benefit_configuration_id        (benefit_configuration_id)
#  index_benefits_on_consumer_id                     (consumer_id)
#  index_benefits_unique_active_per_consumer_config  (consumer_id,benefit_configuration_id) UNIQUE WHERE (status = 0)
#
# Foreign Keys
#
#  fk_rails_...  (benefit_configuration_id => benefit_configurations.id)
#  fk_rails_...  (consumer_id => consumers.id)
#
