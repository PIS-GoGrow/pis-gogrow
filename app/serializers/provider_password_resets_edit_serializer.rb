# frozen_string_literal: true

class ProviderPasswordResetsEditSerializer < ApplicationSerializer
  typelize email: :string
  attributes :email
end
