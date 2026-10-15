# frozen_string_literal: true

require "rails_helper"
require "fugit"

RSpec.describe "config/recurring.yml" do
  def recurring_config
    YAML.safe_load(Rails.root.join("config/recurring.yml").read).fetch("production")
  end

  it "runs at 10:00 on weekdays in America/Montevideo" do
    schedule = recurring_config.dig("provider_menu_unpublished_reminders", "schedule")

    expect(schedule).to eq("every weekday at 10:00 America/Montevideo")
    expect(Fugit.parse(schedule).to_cron_s).to eq("0 10 * * 1,2,3,4,5 America/Montevideo")
  end

  it "cleans obsolete notifications daily after midnight in America/Montevideo" do
    schedule = recurring_config.dig("provider_menu_unpublished_notifications_cleanup", "schedule")

    expect(schedule).to eq("every day at 00:05 America/Montevideo")
    expect(Fugit.parse(schedule).to_cron_s).to eq("5 0 * * * America/Montevideo")
  end
end
