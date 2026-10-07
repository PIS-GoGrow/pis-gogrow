# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    user { nil }
    title { "MyString" }
    description { "MyString" }
    requires_action { false }
    closed { false }
  end
end

# == Schema Information
#
# Table name: notifications
#
#  id                            :bigint           not null, primary key
#  closed_at                     :datetime
#  description                   :string
#  requires_action               :boolean
#  title                         :string
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  notification_configuration_id :bigint           not null
#  user_id                       :bigint           not null
#
# Indexes
#
#  index_notifications_on_notification_configuration_id  (notification_configuration_id)
#  index_notifications_on_user_id                        (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (notification_configuration_id => notification_configurations.id)
#  fk_rails_...  (user_id => users.id)
#
