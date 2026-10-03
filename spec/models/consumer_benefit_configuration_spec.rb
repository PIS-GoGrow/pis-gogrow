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

# == Schema Information
#
# Table name: consumer_benefit_configurations
#
#  id                       :bigint           not null, primary key
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  benefit_configuration_id :bigint           not null
#  consumer_id              :bigint           not null
#
# Indexes
#
#  idx_on_benefit_configuration_id_5005c4988d            (benefit_configuration_id)
#  index_consumer_benefit_configurations_on_consumer_id  (consumer_id)
#
# Foreign Keys
#
#  fk_rails_...  (benefit_configuration_id => benefit_configurations.id)
#  fk_rails_...  (consumer_id => consumers.id)
#
