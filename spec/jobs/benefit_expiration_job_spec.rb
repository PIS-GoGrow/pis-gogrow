# frozen_string_literal: true

require "rails_helper"

RSpec.describe BenefitExpirationJob, type: :job do
  fixtures :benefits, :consumers, :companies, :users, :benefit_configurations

  describe "#perform" do
    include ActiveJob::TestHelper

    it "expires past due benefits and enqueues BenefitAssignationJob" do
      past_benefit = benefits(:monthly)
      past_benefit.update_columns(due_date: Date.current - 1.day, status: Benefit.statuses[:current])

      expect {
        described_class.perform_now
      }.to have_enqueued_job(BenefitAssignationJob)

      expect(past_benefit.reload).to be_expired
    end

    it "accepts a custom date" do
      target_date = Date.current + 5.days
      future_benefit = benefits(:monthly)
      future_benefit.update_columns(due_date: Date.current + 2.days, status: Benefit.statuses[:current])

      described_class.perform_now(date: target_date)
      expect(future_benefit.reload).to be_expired
    end
  end
end
