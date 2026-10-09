# frozen_string_literal: true

class Notification::ConfigurationUser < ApplicationRecord
  belongs_to :notification_configuration, class_name: "Notification::Configuration"
  belongs_to :user
end

# == Schema Information
#
# Table name: notification_configuration_users
#
#  id                            :bigint           not null, primary key
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  notification_configuration_id :bigint           not null
#  user_id                       :bigint           not null
#
# Indexes
#
#  idx_on_notification_configuration_id_0b0ca12e05    (notification_configuration_id)
#  index_notification_configuration_users_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (notification_configuration_id => notification_configurations.id)
#  fk_rails_...  (user_id => users.id)
#
