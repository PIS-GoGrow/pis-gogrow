# frozen_string_literal: true

class Provider::MenusNewSerializer < ApplicationSerializer
  typelize today: :string, maximum_publish_date: :string
  attributes :today, :maximum_publish_date
end
