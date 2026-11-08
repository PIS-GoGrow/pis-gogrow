# frozen_string_literal: true

require "rails_helper"

RSpec.describe WhatsappSenderJob, type: :job do
  describe "#perform" do
    it "no realiza envíos si el servicio no está configurado" do
      expect {
        described_class.new.perform(:test_event, {}, {}, "+59899123456")
      }.not_to raise_error
    end

    it "retorna nil si el teléfono no está presente" do
      expect(described_class.new.perform(:test_event, {}, {}, nil)).to be_nil
      expect(described_class.new.perform(:test_event, {}, {}, "")).to be_nil
    end
  end
end
