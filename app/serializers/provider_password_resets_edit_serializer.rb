# frozen_string_literal: true

class ProviderPasswordResetsEditSerializer < ApplicationSerializer
  typelize email: :string?, completed: :boolean
  attributes :email, :completed
end
