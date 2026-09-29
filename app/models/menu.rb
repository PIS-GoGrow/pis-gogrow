# frozen_string_literal: true

class Menu < ApplicationRecord
  belongs_to :provider

  has_many :schedules, dependent: :destroy
  has_many :reviews, -> { order(created_at: :desc) }, dependent: :destroy
  has_many :option_groups, class_name: "MenuOptionGroup", dependent: :destroy

  accepts_nested_attributes_for :option_groups, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true
  validates :price, comparison: { greater_than: 0 }

  def provider_name
    provider.user&.name || "Proveedor"
  end
end

# == Schema Information
#
# Table name: menus
#
#  id          :bigint           not null, primary key
#  description :string
#  name        :string
#  price       :decimal(10, 2)
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
