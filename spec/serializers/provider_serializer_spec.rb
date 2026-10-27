# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProviderSerializer do
  fixtures :users, :providers

  describe "#to_h" do
    it "serializes provider attributes including home_delivery" do
      provider = providers(:tuviandita)
      serialized = described_class.new(provider).to_h

      expect(serialized).to eq(
        "id" => provider.id,
        "name" => provider.user.name,
        "home_delivery" => true
      )
    end

    it "serializes home_delivery as false when disabled" do
      provider = providers(:office_provider)
      serialized = described_class.new(provider).to_h

      expect(serialized["home_delivery"]).to be false
    end
  end
end

# == Schema Information
#
# Table name: providers
#
#  id                            :bigint           not null, primary key
#  bank_account_holder           :string
#  bank_account_number           :string
#  bank_account_type             :integer
#  bank_name                     :string
#  deliveries_configured_at      :datetime
#  home_delivery                 :boolean          default(TRUE), not null
#  notifications_configured_at   :datetime
#  onboarding_completed_at       :datetime
#  order_deadline                :time
#  order_deadline_configured_at  :datetime
#  payment_details_configured_at :datetime
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  tax_id                        :string
#  user_id                       :bigint
#
# Indexes
#
#  index_providers_on_user_id  (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
