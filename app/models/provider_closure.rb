# frozen_string_literal: true

# Un rango de fechas, de starts_on a ends_on inclusive, en el que el proveedor
# no recibe pedidos. Dos proveedores pueden tener el mismo rango: cada uno
# guarda el suyo.
class ProviderClosure < ApplicationRecord
  belongs_to :provider

  validates :starts_on, :ends_on, presence: true
  validates :reason, presence: true, length: { maximum: 100 }
  validates :ends_on, comparison: { greater_than_or_equal_to: :starts_on }, allow_nil: true
  validates :starts_on, comparison: { greater_than_or_equal_to: -> { Date.current } },
    allow_nil: true, if: -> { new_record? || starts_on_changed? }
  validate :does_not_overlap_other_closures

  scope :upcoming, -> { where(ends_on: Date.current..).order(:starts_on) }

  def covers?(date)
    date.between?(starts_on, ends_on)
  end

  private

  def does_not_overlap_other_closures
    return if provider.nil? || starts_on.nil? || ends_on.nil?

    overlapping = provider.closures.where.not(id:).where(starts_on: ..ends_on, ends_on: starts_on..)
    errors.add(:base, :overlaps) if overlapping.exists?
  end
end

# == Schema Information
#
# Table name: provider_closures
#
#  id          :bigint           not null, primary key
#  ends_on     :date             not null
#  reason      :string           not null
#  starts_on   :date             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  provider_id :bigint           not null
#
# Indexes
#
#  index_provider_closures_on_provider_id                (provider_id)
#  index_provider_closures_on_provider_id_and_starts_on  (provider_id,starts_on)
#
# Foreign Keys
#
#  fk_rails_...  (provider_id => providers.id)
#
