# frozen_string_literal: true

require "rails_helper"
require "fugit"

RSpec.describe "config/recurring.yml" do
  def reminder_schedule
    YAML.safe_load(Rails.root.join("config/recurring.yml").read)
      .dig("production", "provider_menu_unpublished_reminders", "schedule")
  end

  it "runs at 10:00 on weekdays in America/Montevideo" do
    schedule = reminder_schedule

    expect(schedule).to eq("every weekday at 10:00 America/Montevideo")
    expect(Fugit.parse(schedule).to_cron_s).to eq("0 10 * * 1,2,3,4,5 America/Montevideo")
  end
end
