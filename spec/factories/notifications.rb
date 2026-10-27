# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    user { nil }
    title { "MyString" }
    description { "MyString" }
    requires_action { false }
  end
end

# == Schema Information
#
# Table name: notifications
#
#  id                            :bigint           not null, primary key
#  closed_at                     :datetime
#  delivered_at                  :datetime
#  description_data              :json
#  event                         :string           not null
#  failed                        :boolean
#  notifiable_type               :string           not null
#  requires_action               :boolean          not null
#  role                          :string           not null
#  send_attempts                 :integer          default(0)
#  title_data                    :json
#  twilio_sid                    :string
#  whatsapp_sent_at              :datetime
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  notifiable_id                 :bigint           not null
#  notification_configuration_id :bigint           not null
#  user_id                       :bigint           not null
#
# Indexes
#
#  index_notifications_on_notifiable                     (notifiable_type,notifiable_id)
#  index_notifications_on_notification_configuration_id  (notification_configuration_id)
#  index_notifications_on_twilio_sid                     (twilio_sid)
#  index_notifications_on_user_id                        (user_id)
#  index_notifications_one_active_per_event              (notifiable_type,notifiable_id,event,user_id) UNIQUE WHERE (closed_at IS NULL)
#
# Foreign Keys
#
#  fk_rails_...  (notification_configuration_id => notification_configurations.id)
#  fk_rails_...  (user_id => users.id)
#
