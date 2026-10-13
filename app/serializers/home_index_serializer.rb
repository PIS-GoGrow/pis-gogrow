# frozen_string_literal: true

class HomeIndexSerializer < ApplicationSerializer
  typelize variant: "'consumer' | 'provider' | 'admin'", dev_login_enabled: :boolean
  attributes :variant, :dev_login_enabled
end
