# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Scheduler de recordatorios de pedidos", type: :job do
  let(:production_tasks) do
    YAML.safe_load(
      Rails.root.join("config/recurring.yml").read
    ).fetch("production")
  end

  let(:task_key) { "employee_order_reminders" }

  let(:task) do
    SolidQueue::RecurringTask.from_configuration(
      task_key,
      **production_tasks.fetch(task_key).symbolize_keys
    )
  end

  it "configura el job recurrente de recordatorios de pedidos" do
    expect(task.class_name).to eq("EmployeeOrderRemindersJob")
  end
end
