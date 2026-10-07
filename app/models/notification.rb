# frozen_string_literal: true

#
class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notification_configuration

  validates :title, presence: true
  validates :description, presence: true

  scope :closed, -> { where.not closed_at: nil }
  scope :active, -> { where closed_at: nil }

  after_create_commit :send_whatsapp

  def close!(time: Time.current)
    update! closed_at: time
  end

  private

  def send_whatsapp
    # TODO: a definir
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
