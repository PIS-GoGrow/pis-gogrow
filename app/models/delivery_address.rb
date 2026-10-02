# frozen_string_literal: true

class DeliveryAddress < ApplicationRecord
  # Una calle con al menos una letra y el número de puerta: "Ellauri 1234".
  STREET_FORMAT = /\A(?=.*\p{L})(?=.*\d).+\z/

  belongs_to :consumer

  validates :name, presence: true, length: { maximum: 40 }
  validates :street, presence: true, length: { maximum: 120 }, format: { with: STREET_FORMAT, allow_blank: true }
  validates :apartment, length: { maximum: 40 }

  normalizes :name, :street, :apartment, with: ->(value) { value.squish.presence }

  def self.valid_full_address?(value)
    value.to_s.squish.length.between?(1, 164) && value.to_s.match?(STREET_FORMAT)
  end

  def full_address
    [ street, apartment ].compact_blank.join(", ")
  end
end

# == Schema Information
#
# Table name: delivery_addresses
#
#  id          :bigint           not null, primary key
#  apartment   :string
#  name        :string           not null
#  street      :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  consumer_id :bigint           not null
#
# Indexes
#
#  index_delivery_addresses_on_consumer_id  (consumer_id)
#
# Foreign Keys
#
#  fk_rails_...  (consumer_id => consumers.id)
#
