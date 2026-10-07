# frozen_string_literal: true

# Representa una notificación que se le va a enviar al usuario.
# Una notificación puede estar activa o cerrada y puede requerir o no acción.
# Si requiere acción, el usuario no la puede cerrar
class Notification < ApplicationRecord
  EVENT_KEYS = %i[order_confirmation].freeze

  belongs_to :user
  belongs_to :notification_configuration

  validates :title, presence: true
  validates :description, presence: true
  validates :role_belongs_to_user
  validates :event_exists

  scope :closed, -> { where.not closed_at: nil }
  scope :active, -> { where closed_at: nil }

  after_create_commit :send_whatsapp

  def close!(time: Time.current)
    update! closed_at: time
  end

  def self.close_by!(event_key, notifiable, user)
    user
      .notifications
      .active
      .where(event_key:, notifiable:)
      .first!
      .close!
  end

  private

  def send_whatsapp
    # TODO: a definir
  end

  def role_belongs_to_user
    user.roles.include? role
  end

  def event_exists
    EVENT_KEYS.include? event.to_sym
  end
end

# == Schema Information
#
# Table name: notifications
#
#  id                            :bigint           not null, primary key
#  closed_at                     :datetime
#  description                   :string
#  event                         :string           not null
#  notifiable_type               :string           not null
#  requires_action               :boolean          not null
#  role                          :string           not null
#  title                         :string
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
#  index_notifications_on_user_id                        (user_id)
#  index_notifications_one_active_per_event              (notifiable_type,notifiable_id,event) UNIQUE WHERE ((closed_at IS NULL) AND (requires_action = true))
#
# Foreign Keys
#
#  fk_rails_...  (notification_configuration_id => notification_configurations.id)
#  fk_rails_...  (user_id => users.id)
#
