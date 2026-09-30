# frozen_string_literal: true

class AddAvailabilityToSchedules < ActiveRecord::Migration[8.1]
  def change
    add_column :schedules, :available, :boolean, null: false, default: true
    add_column :schedules, :availability_changed_at, :datetime
    add_reference :schedules, :availability_changed_by, foreign_key: { to_table: :users }
  end
end
