# frozen_string_literal: true

require "rails_helper"

RSpec.describe Settings::ProfilesShowSerializer do
  fixtures :users, :providers

  describe "#to_h" do
    it "serializes provider when present" do
      provider = providers(:tuviandita)
      serialized = described_class.new({ provider: provider, phone: nil }).to_h

      expect(serialized["provider"]).to eq(
        "id" => provider.id,
        "name" => provider.user.name,
        "home_delivery" => true
      )
    end

    it "serializes the user's phone" do
      serialized = described_class.new({ provider: nil, phone: "+59899123456" }).to_h

      expect(serialized["phone"]).to eq("+59899123456")
    end

    it "serializes provider as nil when absent" do
      serialized = described_class.new({ provider: nil, phone: nil }).to_h

      expect(serialized["provider"]).to be_nil
    end
  end
end
