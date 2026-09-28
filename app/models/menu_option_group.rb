# frozen_string_literal: true

class MenuOptionGroup < ApplicationRecord
  belongs_to :menu

  validates :name, presence: true
  validates :limit, numericality: { only_integer: true, greater_than: 0 }
  validate :options_values_valid

  private

  def options_values_valid
    return if options.all?(&:present?) && options.uniq.size == options.size
    errors.add(:options, :invalid)
  end
end

# == Schema Information
#
# Table name: menu_option_groups
#
#  id         :bigint           not null, primary key
#  limit      :integer          default(1), not null
#  name       :string           not null
#  options    :string           default([]), is an Array
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  menu_id    :bigint           not null
#
# Indexes
#
#  index_menu_option_groups_on_menu_id  (menu_id)
#
# Foreign Keys
#
#  fk_rails_...  (menu_id => menus.id)
#
