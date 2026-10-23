# frozen_string_literal: true

require "rails_helper"

RSpec.describe EmployeeOrderRemindersJob, type: :job do
  it "delegates reminder generation with the execution date and time" do
    date = Date.new(2030, 1, 9)
    now = Time.zone.local(2030, 1, 9, 11)

    allow(OrderReminders::Generate).to receive(:call)

    described_class.perform_now(date:, now:)

    expect(OrderReminders::Generate)
      .to have_received(:call)
      .with(date:, now:)
  end
end
