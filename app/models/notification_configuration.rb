# frozen_string_literal: true

class NotificationConfiguration < ApplicationRecord
  has_many :user_notification_configurations, dependent: :destroy
  has_many :users, through: :user_notification_configurations, source: :user

  has_many :notifications, dependent: :destroy

  validates :title, presence: true
  validates :description, presence: true
end

# == Schema Information
#
# Table name: notification_configurations
#
#  id          :bigint           not null, primary key
#  description :string
#  key         :string           not null
#  title       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_notification_configurations_on_key  (key) UNIQUE
#
