# frozen_string_literal: true

class Notifier
  def self.call(event_key: nil, configuration_key:, role:, user:, requires_action:, title_data: {}, description_data: {})
    event_key ||= configuration_key

    # Lanzamos error si la configuration_key es incorrecta
    configuration = NotificationConfiguration.find_by!(key: configuration_key)

    # I18n.t! lanza I18n::MissingTranslationData si falta la traducción, en vez de
    # guardar un texto tipo "translation missing: ..." en la notificación.
    Notification.create!(
      notification_configuration: configuration,
      user:,
      role:,
      requires_action:,
      title: I18n.t!("notifications.#{event_key}.title", **title_data),
      description: I18n.t!("notifications.#{event_key}.description", **description_data)
    )
  rescue ActiveRecord::RecordInvalid => e
    # El único error que permitimos es si no se pudo crear la notificación.
    # En ese caso, no queremos que el usuario no pueda completar su acción porque
    # no se pueden enviar las notificaciones.
    Rails.logger.error("[Notifier] #{e.class}: #{e.message}")
    nil
  end
end
