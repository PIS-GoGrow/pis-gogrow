# frozen_string_literal: true

require "rails_helper"

RSpec.describe Settings::ProfilesShowSerializer do
  describe "#to_h" do
    it "serializes the user's phone" do
      serialized = described_class.new({ phone: "+59899123456" }).to_h

      expect(serialized["phone"]).to eq("+59899123456")
    end

    it "does not expose provider delivery settings" do
      serialized = described_class.new({ phone: nil }).to_h

      expect(serialized).to eq("phone" => nil)
    end
  end
end
