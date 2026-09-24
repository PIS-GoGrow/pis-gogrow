# frozen_string_literal: true

class Menu < ApplicationRecord
  validates :name, presence: true
  validates :price, comparison: { greater_than: 0 }

  belongs_to :provider

  has_many :schedules, dependent: :destroy
  has_many :reviews, -> { order(created_at: :desc) }, dependent: :destroy
end

# == Schema Information
#
# Table name: menus
#
#  id          :bigint           not null, primary key
#  description :string
#  fillings    :string           default([]), not null, is an Array
#  name        :string
#  price       :decimal(10, 2)
#  sauces      :string           default([]), not null, is an Array
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  provider_id :bigint           not null
#
# Indexes
#
#  index_menus_on_provider_id  (provider_id)
#
# Foreign Keys
#
#  fk_rails_...  (provider_id => providers.id)
#
