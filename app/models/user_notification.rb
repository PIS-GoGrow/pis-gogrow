# frozen_string_literal: true

class UserNotification < ApplicationRecord
  belongs_to :notification_configuration
  belongs_to :user, polymorphic: true
end
