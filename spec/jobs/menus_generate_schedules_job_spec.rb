# frozen_string_literal: true

require "rails_helper"

RSpec.describe MenusGenerateSchedulesJob, type: :job do
  it "delegates schedule generation to Menus::AgendaScheduler.call_all" do
    allow(Menus::AgendaScheduler).to receive(:call_all)

    described_class.perform_now

    expect(Menus::AgendaScheduler).to have_received(:call_all)
  end
end
