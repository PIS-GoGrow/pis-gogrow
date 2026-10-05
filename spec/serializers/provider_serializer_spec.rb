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
