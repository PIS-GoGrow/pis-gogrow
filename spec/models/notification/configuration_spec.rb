# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notification::Configuration do
  describe ".for_role" do
    it "devuelve solo los grupos que incluyen ese rol" do
      expect(described_class.for_role(:consumer).pluck(:key))
        .to contain_exactly("order_updates", "provider_payment_reminders", "automatic_payment_reminders", "debt_alerts", "hr_payment_reminders")
      expect(described_class.for_role(:admin).pluck(:key)).to contain_exactly(
        "company_payments",
        "employee_debts",
        "hr_partial_payments",
        "hr_pending_invoices",
        "hr_pending_payments",
        "hr_rejected_receipts",
        "hr_subsidy_changes"
      )
      expect(described_class.for_role(:provider).pluck(:key))
        .to contain_exactly("provider_orders", "provider_payments", "order_cancellations", "menu_publication_reminders")
    end
  end
end

# == Schema Information
#
# Table name: notification_configurations
#
#  id           :bigint           not null, primary key
#  configurable :boolean
#  key          :string           not null
#  roles        :string           default([]), is an Array
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_notification_configurations_on_key  (key) UNIQUE
#
