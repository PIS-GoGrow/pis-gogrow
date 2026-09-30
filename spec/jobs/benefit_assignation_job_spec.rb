# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitAssignationJob, type: :job do
  fixtures :benefit_configurations, :benefit_rules, :consumers, :companies, :users, :consumer_benefit_configurations

  describe "#perform" do
    it "calls apply_to_all_consumers on each benefit configuration" do
      configs = [ benefit_configurations(:monthly), benefit_configurations(:gift) ]
      configs.each do |config|
        expect(config).to receive(:apply_to_all_consumers).and_call_original
      end
      allow(BenefitConfiguration).to receive(:includes).and_return(BenefitConfiguration)
      allow(BenefitConfiguration).to receive(:find_each).and_yield(configs.first).and_yield(configs.last)

      described_class.perform_now
    end

    it "handles and reports errors without crashing the entire job" do
      failing_config = benefit_configurations(:monthly)
      allow(failing_config).to receive(:apply_to_all_consumers).and_raise(StandardError, "Unexpected error")

      allow(BenefitConfiguration).to receive(:includes).and_return(BenefitConfiguration)
      allow(BenefitConfiguration).to receive(:find_each).and_yield(failing_config)

      expect(Rails.error).to receive(:report).with(
        an_instance_of(StandardError),
        context: { benefit_configuration_id: failing_config.id },
        handled: true
      )

      expect { described_class.perform_now }.not_to raise_error
    end
  end
end
