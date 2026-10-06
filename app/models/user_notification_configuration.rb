# frozen_string_literal: true

class UserNotificationConfiguration < ApplicationRecord
  belongs_to :notification_configuration
  belongs_to :user
end

# == Schema Information
#
# Table name: user_notification_configurations
#
#  id                            :bigint           not null, primary key
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  notification_configuration_id :bigint           not null
#  user_id                       :bigint           not null
#
# Indexes
#
#  idx_on_notification_configuration_id_fc2b09c529    (notification_configuration_id)
#  index_user_notification_configurations_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (notification_configuration_id => notification_configurations.id)
#  fk_rails_...  (user_id => users.id)
#
