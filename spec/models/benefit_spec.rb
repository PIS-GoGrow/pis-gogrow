# frozen_string_literal: true

require "rails_helper"

RSpec.describe Benefit, type: :model do
  fixtures :consumers

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

  describe "scopes" do
    it ".current includes benefits due today or in the future and excludes past ones" do
      active = described_class.create!(consumer:, amount: 5, percentage: 50, due_date: Date.current + 2.days)
      today = described_class.create!(consumer:, amount: 5, percentage: 50, due_date: Date.current)
      expired = described_class.create!(consumer:, amount: 5, percentage: 50, due_date: Date.current - 1.day)

      expect(described_class.current).to include(active, today)
      expect(described_class.current).not_to include(expired)
    end

    it ".monthly filters by description 'Viandas mensuales'" do
      monthly = described_class.create!(consumer:, amount: 20, percentage: 50, due_date: 1.month.from_now, description: "Viandas mensuales")
      special = described_class.create!(consumer:, amount: 5, percentage: 100, due_date: 1.month.from_now, description: "Bono especial")

      expect(described_class.monthly).to include(monthly)
      expect(described_class.monthly).not_to include(special)
    end
  end
end

# == Schema Information
#
# Table name: benefits
#
#  id          :bigint           not null, primary key
#  amount      :integer
#  description :string
#  due_date    :date
#  percentage  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  consumer_id :bigint           not null
#
# Indexes
#
#  index_benefits_on_consumer_id  (consumer_id)
#
# Foreign Keys
#
#  fk_rails_...  (consumer_id => consumers.id)
#
