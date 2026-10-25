# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProviderMenuUnpublishedRemindersJob, type: :job do
  it "uses the missing publication detector for the requested date" do
    date = Date.new(2030, 1, 9)
    providers = Provider.none
    allow(Menus::MissingPublicationDetector).to receive(:call).with(date:).and_return(providers)
    allow(Menus::MissingPublicationNotifier).to receive(:call)

    described_class.perform_now(date:)

    expect(Menus::MissingPublicationNotifier).to have_received(:call).with(providers:, date:)
  end
end
