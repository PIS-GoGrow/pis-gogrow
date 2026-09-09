# frozen_string_literal: true

class DashboardIndexSerializer < ApplicationSerializer
  attributes :role
  typelize role: :string?
end
