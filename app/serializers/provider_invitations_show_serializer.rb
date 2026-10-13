# frozen_string_literal: true

class ProviderInvitationsShowSerializer < ApplicationSerializer
  typelize email: :string
  attributes :email
end
