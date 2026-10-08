# frozen_string_literal: true

# Representa una notificación que se le va a enviar al usuario.
# Una notificación puede estar activa o cerrada y puede requerir o no acción.
#
# Si el usuario tiene varios roles, la notificación solo le aparecerá cuando se loguee
# con el rol definido en la columna role de notificación.
class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notification_configuration, class_name: "Notification::Configuration"
  belongs_to :notifiable, polymorphic: true

  validates :title, presence: true
  validates :description, presence: true
  validate :role_belongs_to_user
  validate :event_exists

  scope :closed, -> { where.not(closed_at: nil) }
  scope :active, -> { where(closed_at: nil) }

  after_create_commit :send_whatsapp

  # Cierra la notificación para que ya no le aparezca más al usuario.
  def close!(time: Time.current)
    return if closed_at

    update! closed_at: time
  end

  # Cierra una notificación según un usuario, el objeto que generó la notificación
  # y un evento.
  # Si ya se tiene la notificación, no es necesario pasar por este método, se puede
  # llamar a close! directamente.
  def self.close_by!(event:, notifiable:, user:)
    user
      .notifications
      .active
      .where(event:, notifiable:)
      .first!
      .close!
  end

  # Idéntico a close_by!, solo que no hace nada si la notificación no existe
  def self.close_by(event:, notifiable:, user:)
    user
      .notifications
      .active
      .where(event:, notifiable:)
      .first
      &.close!
  end

  private

  def send_whatsapp
    # TODO: a definir
  end

  def role_belongs_to_user
    errors.add(:role, :invalid) unless user&.roles&.include?(role.to_s)
  end

  def event_exists
    errors.add(:event, :inclusion) unless Notification::Registry.event?(event)
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
#  index_notifications_one_active_per_event              (notifiable_type,notifiable_id,event,user_id) UNIQUE WHERE (closed_at IS NULL)
#
# Foreign Keys
#
#  fk_rails_...  (notification_configuration_id => notification_configurations.id)
#  fk_rails_...  (user_id => users.id)
#
