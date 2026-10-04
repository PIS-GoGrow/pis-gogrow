# frozen_string_literal: true

class ScheduleSerializer < ApplicationSerializer
  typelize_from Schedule

  attributes :id, :menu_id, :amount, :available

  typelize :number
  attribute :saved_menu_id do |schedule|
    schedule.menu.base_menu_id || schedule.menu_id
  end
  one :menu, resource: MenuSerializer
end

# == Schema Information
#
# Table name: schedules
#
#  id                         :bigint           not null, primary key
#  amount                     :integer          not null
#  availability_changed_at    :datetime
#  available                  :boolean          default(TRUE), not null
#  date                       :date             not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  availability_changed_by_id :bigint
#  menu_id                    :bigint           not null
#
# Indexes
#
#  index_schedules_on_availability_changed_by_id  (availability_changed_by_id)
#  index_schedules_on_menu_id                     (menu_id)
#  index_schedules_on_menu_id_and_date            (menu_id,date) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (availability_changed_by_id => users.id)
#  fk_rails_...  (menu_id => menus.id)
#
