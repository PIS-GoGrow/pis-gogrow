# frozen_string_literal: true

class AddDebtAlertThresholdToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :debt_alert_threshold, :integer, default: 2000, null: false
  end
end
