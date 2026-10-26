# frozen_string_literal: true

class Provider::AccountsShowSerializer < ApplicationSerializer
  typelize incomplete_sections: "[string]"
  attributes :incomplete_sections
end
