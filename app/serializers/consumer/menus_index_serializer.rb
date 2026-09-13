# frozen_string_literal: true

class Consumer::MenusIndexSerializer < ApplicationSerializer
  has_many :menus, resource: Consumer::MenuSerializer
end
