# frozen_string_literal: true

class AddBirthdayAndOnboardingDateToConsumers < ActiveRecord::Migration[8.1]
  def change
    add_column :consumers, :birthday, :date
    add_column :consumers, :onboarding_date, :date
  end
end
