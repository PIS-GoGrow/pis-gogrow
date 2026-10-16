# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanyPaymentRemindersJob, type: :job do
  describe "#perform" do
    it "revisa los pagos de la empresa a la fecha indicada" do
      date = Date.new(2026, 9, 2)
      allow(CompanyPaymentNotifications).to receive(:remind!)

      described_class.perform_now(date:)

      expect(CompanyPaymentNotifications).to have_received(:remind!).with(date:)
    end
  end
end
