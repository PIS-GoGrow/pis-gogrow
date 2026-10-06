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
