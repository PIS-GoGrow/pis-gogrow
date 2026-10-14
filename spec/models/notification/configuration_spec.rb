# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notification::Configuration do
  describe ".for_role" do
    it "devuelve solo los grupos que incluyen ese rol" do
      expect(described_class.for_role(:consumer).pluck(:key))
        .to contain_exactly("order_updates", "provider_payment_reminders")
      expect(described_class.for_role(:admin).pluck(:key)).to eq([ "company_payments" ])
      expect(described_class.for_role(:provider)).to be_empty
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
