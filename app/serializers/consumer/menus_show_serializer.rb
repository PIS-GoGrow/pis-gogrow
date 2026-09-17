# frozen_string_literal: true

class Consumer::MenusShowSerializer < ApplicationSerializer
  has_one :menu, resource: Consumer::MenuSerializer
end
