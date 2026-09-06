# frozen_string_literal: true

class NotificationConfiguration < ApplicationRecord
  has_many :user_notifications
  has_many :consumers, through: :user_notifications, source: :user, source_type: "Consumer"
  has_many :admins,    through: :user_notifications, source: :user, source_type: "Admin"
  has_many :providers, through: :user_notifications, source: :user, source_type: "Provider"
end

# == Schema Information
#
# Table name: notification_configurations
#
#  id          :bigint           not null, primary key
#  description :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
