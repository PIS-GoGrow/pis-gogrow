# frozen_string_literal: true

# Representa una notificación que se le va a enviar al usuario.
# Una notificación puede estar activa o cerrada y puede requerir o no acción.
#
# Si el usuario tiene varios roles, la notificación solo le aparecerá cuando se loguee
# con el rol definido en la columna role de notificación.
#
# Ver más documentación en docs/notificaciones.rb
class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notification_configuration, class_name: "Notification::Configuration"
  belongs_to :notifiable, polymorphic: true

  validates :title, presence: true, on: :create
  validates :description, presence: true, on: :create
  validate :role_belongs_to_user, on: :create
  validate :event_exists, on: :create

  # skipped => se decidió no enviar la notificación
  # pending => se decidió enviar, pero todavía no se empezó el proceso
  # sending => se está enviando, no fue aceptada por Twilio todavía
  # accepted => se envió a Twilio, no le llegó al usuario todavía
  # delivered => le llegó a Twilio y al usuario
  # send_failed => no se pudo enviar a Twilio
  # delivery_failed => Twilio no se la pudo enviar al usuario
  enum :whatsapp_send_status,
       { pending: 0, skipped: 1, sending: 2, accepted: 3, delivered: 4, send_failed: 5, delivery_failed: 6 },
       default: :pending

  scope :closed, -> { where.not(closed_at: nil) }
  scope :active, -> { where(closed_at: nil) }

  MAX_SEND_ATTEMPTS = 5

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

  # Determina si mandarle o no una notificación por WhatsApp al usuario.
  # Si el usuario no tiene un teléfono configurado, no la enviamos.
  # Si ya cerró manual o automáticamente la notificación, no la enviamos.
  # Si le estamos mandando una notificación a un proveedor que está cerrado en el día
  # de hoy, no la enviamos.
  # Si la configuración no es configurable, la enviamos. Si sí, nos fijamos si el
  # usuario la tiene configurada.
  def send_to_user?
    return false unless user.phone.present?

    return false if closed_at

    return false if role == "provider" && user.provider&.closed_on?(Date.current)

    return true unless notification_configuration.configurable

    notification_configuration.users.exists? user.id
  end

  def send_attempts_exceeded?
    whatsapp_send_attempts >= MAX_SEND_ATTEMPTS
  end

  def title
    return "" unless event.present?

    data = title_data&.transform_keys(&:to_sym) || {}
    result = I18n.t("notifications.#{event}.title", default: nil, **data)
    result.is_a?(Hash) ? (result[:other] || result[:one] || result.values.first).to_s : result.to_s
  rescue I18n::MissingInterpolationArgument, I18n::ArgumentError
    raw = I18n.t("notifications.#{event}.title", default: event.to_s.humanize)
    raw.is_a?(Hash) ? (raw[:other] || raw[:one] || raw.values.first).to_s : raw.to_s
  end

  def description
    return "" unless event.present?

    data = description_data&.transform_keys(&:to_sym) || {}
    data = { count: 1 }.merge(data) unless data.key?(:count)

    result = I18n.t("notifications.#{event}.description", default: nil, **data)
    if result.is_a?(Hash)
      (result[:other] || result[:one] || result.values.first).to_s
    else
      result.to_s
    end
  rescue I18n::MissingInterpolationArgument, I18n::ArgumentError
    raw = I18n.t("notifications.#{event}.description", default: "")
    if raw.is_a?(Hash)
      (raw[:other] || raw[:one] || raw.values.first).to_s
    else
      raw.to_s
    end
  end

  private

  def role_belongs_to_user
    user&.sync_roles!
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
#  delivered_at                  :datetime
#  description_data              :json
#  event                         :string           not null
#  notifiable_type               :string           not null
#  requires_action               :boolean          not null
#  role                          :string           not null
#  title_data                    :json
#  twilio_sid                    :string
#  whatsapp_last_sent_at         :datetime
#  whatsapp_send_attempts        :integer          default(0)
#  whatsapp_send_status          :integer
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
