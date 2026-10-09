# frozen_string_literal: true

class NotificationSerializer < ApplicationSerializer
  attributes :id, :title, :description, :requires_action
end
