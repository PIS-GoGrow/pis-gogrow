# frozen_string_literal: true

class MenuSerializer < ApplicationSerializer
  typelize_from Menu

  attributes :id, :name, :description, :price, :created_at, :updated_at

  typelize "{ id: number; name: string; options: string[]; limit: number }[]"
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
#  id              :bigint           not null, primary key
#  description     :string
#  modified_at     :datetime
#  modified_values :jsonb
#  name            :string
#  price           :decimal(10, 2)
#  valid_from      :date
#  valid_until     :date
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  base_menu_id    :bigint
#  modified_by_id  :bigint
#  provider_id     :bigint           not null
#
# Indexes
#
#  index_menus_on_base_menu_id    (base_menu_id)
#  index_menus_on_modified_by_id  (modified_by_id)
#  index_menus_on_provider_id     (provider_id)
#
# Foreign Keys
#
#  fk_rails_...  (base_menu_id => menus.id)
#  fk_rails_...  (modified_by_id => users.id)
#  fk_rails_...  (provider_id => providers.id)
#
