# frozen_string_literal: true

class ProviderInvitationsShowSerializer < ApplicationSerializer
  typelize email: :string?, completed: :boolean
  attributes :email, :completed
end
