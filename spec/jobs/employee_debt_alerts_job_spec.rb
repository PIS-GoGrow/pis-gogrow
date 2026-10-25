# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmployeeDebtAlertsJob, type: :job do
  describe "#perform" do
    it "revisa las deudas de los empleados a la fecha indicada" do
      date = Date.new(2026, 11, 11)
      allow(EmployeeDebtNotifications).to receive(:remind!)

      described_class.perform_now(date:)

      expect(EmployeeDebtNotifications).to have_received(:remind!).with(date:)
    end
  end
end
