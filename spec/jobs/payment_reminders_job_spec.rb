# frozen_string_literal: true

require "rails_helper"

RSpec.describe PaymentRemindersJob, type: :job do
  describe "#perform" do
    it "generates payment reminders for today" do
      date = Date.new(2026, 11, 7)

      expect(PaymentReminders::Generate)
        .to receive(:call)
        .with(date:)

      described_class.perform_now(date:)
    end
  end
end
