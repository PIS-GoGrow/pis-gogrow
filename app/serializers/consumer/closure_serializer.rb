# frozen_string_literal: true

class Consumer::ClosureSerializer < ProviderClosureSerializer
  attributes :provider_id

  typelize :string
  attribute :provider_name do |closure|
    closure.provider.user.name
  end
end
