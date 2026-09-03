# frozen_string_literal: true

class UserNotification < ApplicationRecord
  belongs_to :notification_configuration
  belongs_to :user, polymorphic: true
end

# == Schema Information
#
# Table name: user_notifications
#
#  id                            :bigint           not null, primary key
#  user_type                     :string           not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  notification_configuration_id :bigint           not null
#  user_id                       :bigint           not null
#
# Indexes
#
#  index_user_notifications_on_notification_configuration_id  (notification_configuration_id)
#  index_user_notifications_on_user                           (user_type,user_id)
#
# Foreign Keys
#
#  fk_rails_...  (notification_configuration_id => notification_configurations.id)
#
