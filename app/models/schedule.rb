# frozen_string_literal: true

class Schedule < ApplicationRecord
  belongs_to :menu

  # Hay que validar que este sea el comportamiento esperado
  has_many :orders, dependent: :nullify
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
