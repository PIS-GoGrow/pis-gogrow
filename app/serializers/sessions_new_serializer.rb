# frozen_string_literal: true

class SessionsNewSerializer < ApplicationSerializer
  typelize dev_login_enabled: :boolean
  attributes :dev_login_enabled
end
