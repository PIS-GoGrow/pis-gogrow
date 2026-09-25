# frozen_string_literal: true

module Settings
  class ProfilesShowSerializer < ApplicationSerializer
    typelize provider: "Provider | null"
    one :provider
  end
end
