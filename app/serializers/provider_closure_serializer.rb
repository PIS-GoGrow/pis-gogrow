# frozen_string_literal: true

class ProviderClosureSerializer < ApplicationSerializer
  typelize_from ProviderClosure

  attributes :id, :starts_on, :ends_on, :reason

  # Formateado en el servidor: el SSR corre en UTC y el cliente no.
  typelize :string
  attribute :period do |closure|
    DateFormat.short_range(closure.starts_on, closure.ends_on)
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
