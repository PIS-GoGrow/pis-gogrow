# frozen_string_literal: true

FactoryBot.define do
  factory :menu do
    name { "MyString" }
    description { "MyString" }
    price { "9.99" }
    provider { nil }
  end
end

# == Schema Information
#
# Table name: menus
#
#  id           :bigint           not null, primary key
#  description  :string
#  name         :string
#  price        :decimal(10, 2)
#  valid_from   :date
#  valid_until  :date
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  base_menu_id :bigint
#  provider_id  :bigint           not null
#
# Indexes
#
#  index_menus_on_base_menu_id  (base_menu_id)
#  index_menus_on_provider_id   (provider_id)
#
# Foreign Keys
#
#  fk_rails_...  (base_menu_id => menus.id)
#  fk_rails_...  (provider_id => providers.id)
#
