# frozen_string_literal: true

class MenuSerializer < ApplicationSerializer
  typelize_from Menu

  attributes :id, :name, :description, :price, :created_at, :updated_at

  attribute :option_groups do |menu|
    menu.option_groups.map do |g|
      { id: g.id, name: g.name, options: g.options, limit: g.limit }
    end
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
