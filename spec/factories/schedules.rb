# frozen_string_literal: true

FactoryBot.define do
  factory :schedule do
    date { Date.current }
    amount { 10 }
    menu
  end
end

# == Schema Information
#
# Table name: schedules
#
#  id         :bigint           not null, primary key
#  amount     :integer
#  date       :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  menu_id    :bigint           not null
#
# Indexes
#
#  index_schedules_on_menu_id  (menu_id)
#
# Foreign Keys
#
#  fk_rails_...  (menu_id => menus.id)
#
