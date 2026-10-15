# frozen_string_literal: true

class Consumer::ClosureSerializer < ProviderClosureSerializer
  typelize :string
  attribute :provider_name do |closure|
    closure.provider.user.name
  end
end
