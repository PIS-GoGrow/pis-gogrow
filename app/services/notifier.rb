# frozen_string_literal: true

# Notifier crea una notificación. Una vez creada, no hay que preocuparse por cómo
# se le muestra al usuario o si se envía, esto se hace automáticamente.
#
# Ver más documentación en docs/notificaciones.rb
class Notifier
  class MissingConfiguration < StandardError; end

  def self.call(event_key:, user:, notifiable:, title_data: {}, description_data: {})
    # Buscamos el evento indicado y la Notification::Configuration correspondiente
    event = Notification::Registry.event!(event_key)
    configuration = find_configuration_for! event

    notification = Notification.new(
      notification_configuration: configuration,
      user:,
      role: event.role,
      event: event.key,
      requires_action: event.requires_action,
      notifiable:,
      title_data: title_data,
      description_data: description_data
    )

    send = notification.send_to_user?
    notification.whatsapp_send_status = send ? :pending : :skipped
    notification.save!

    WhatsappSenderJob.perform_later(notification) if send

    notification
  rescue ActiveRecord::RecordInvalid => e
    # El único error que permitimos es si no se pudo crear la notificación.
    # En ese caso, no queremos que el usuario no pueda completar su acción porque
    # no se pueden enviar las notificaciones.
    Rails.logger.error("[Notifier] #{e.class}: #{e.message}")
    nil
  end

  private

  # Devuelve la Notification::Configuration para un evento. Si no está, devolvemos un
  # error explicativo.
  def self.find_configuration_for!(event)
    Notification::Configuration.find_by(key: event.configuration_key.to_s) || raise(
      MissingConfiguration,
      "Se trató crear una notificación incorrectamente: " \
      "No existe la configuración '#{event.configuration_key}' (evento '#{event.key}'). " \
      "Probá corriendo 'rails notifications:sync' o corrigiendo config/notifications.yml."
    )
  end
end
