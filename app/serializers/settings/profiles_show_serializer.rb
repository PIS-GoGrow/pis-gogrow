# frozen_string_literal: true

module Settings
  class ProfilesShowSerializer < ApplicationSerializer
    typelize phone: "string | null"
    attributes :phone
  end
end
