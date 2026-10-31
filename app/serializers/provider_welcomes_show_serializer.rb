# frozen_string_literal: true

class ProviderWelcomesShowSerializer < ApplicationSerializer
  typelize username: :string, company_name: :string, invitation_path: :string
  attributes :username, :company_name, :invitation_path
end
