# frozen_string_literal: true

class ProviderSerializer < ApplicationSerializer
  attributes :id, :home_delivery

  typelize :string
  attribute :name do |provider|
    provider.user.name
  end
end

# == Schema Information
#
# Table name: providers
#
#  id             :bigint           not null, primary key
#  home_delivery  :boolean          default(TRUE), not null
#  order_deadline :time
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  user_id        :bigint
#
# Indexes
#
#  index_providers_on_user_id  (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
