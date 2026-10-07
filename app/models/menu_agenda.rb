# frozen_string_literal: true

# Días de la semana en los que se programa un plato, desde starts_on y, si
# ends_on está, hasta esa fecha. Un plato guardado puede tener varias en el
# tiempo (cambiar la agenda desde una fecha cierra la anterior); una variante
# tiene a lo sumo una, que cubre su rango.
class MenuAgenda < ApplicationRecord
  belongs_to :menu

  validates :starts_on, presence: true
  validates :ends_on, comparison: { greater_than_or_equal_to: :starts_on }, allow_nil: true
  validates :amount, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: Schedule::MAX_AMOUNT }, allow_nil: true
  validate :weekdays_are_working_days

  def dates_until(limit)
    from = [ starts_on, Date.current ].max
    to = [ ends_on, limit ].compact.min
    return [] if from > to

    (from..to).select { |date| weekdays.include?(date.cwday) }
  end

  private

  def weekdays_are_working_days
    errors.add(:weekdays, :invalid) if weekdays.blank? || !weekdays.all? { |day| (1..5).cover?(day) }
  end
end

# == Schema Information
#
# Table name: menu_agendas
#
#  id         :bigint           not null, primary key
#  amount     :integer
#  ends_on    :date
#  starts_on  :date             not null
#  weekdays   :integer          default([]), not null, is an Array
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  menu_id    :bigint           not null
#
# Indexes
#
#  index_menu_agendas_on_menu_id  (menu_id)
#
# Foreign Keys
#
#  fk_rails_...  (menu_id => menus.id)
#
