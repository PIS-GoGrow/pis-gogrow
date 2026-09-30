# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConsumerBenefitConfiguration, type: :model do
  fixtures :benefit_configurations, :consumers, :companies, :users

  describe "associations" do
    let(:cbc) do
      ConsumerBenefitConfiguration.create!(
        benefit_configuration: benefit_configurations(:monthly),
        consumer: consumers(:one)
      )
    end

    it "belongs to a benefit_configuration" do
      expect(cbc.benefit_configuration).to eq(benefit_configurations(:monthly))
    end

    it "belongs to a consumer" do
      expect(cbc.consumer).to eq(consumers(:one))
    end

    it "requires both benefit_configuration and consumer" do
      expect(ConsumerBenefitConfiguration.new).not_to be_valid
      expect(ConsumerBenefitConfiguration.new(benefit_configuration: benefit_configurations(:monthly))).not_to be_valid
      expect(ConsumerBenefitConfiguration.new(consumer: consumers(:one))).not_to be_valid
    end
  end
end
