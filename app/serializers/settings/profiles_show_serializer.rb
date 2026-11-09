# frozen_string_literal: true

module Settings
  class ProfilesShowSerializer < ApplicationSerializer
    typelize phone: "string | null"
    attributes :phone

    typelize provider: "Provider | null"
    one :provider
  end
end
