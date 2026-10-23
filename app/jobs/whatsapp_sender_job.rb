# frozen_string_literal: true

# Envía un mensaje de WhatsApp a un número de celular.
# Este Job no debería ser accedido desde ningún lugar, menos el servicio Notifier.
# Ver más documentación en docs/notificaciones.md
class WhatsappSenderJob < ApplicationJob
  # Errores que se reintentan y que no
  class TransientTwilioError < StandardError; end
  class PermanentTwilioError < StandardError; end

  # No reintentamos si: hay un error de autenticación, el número del usuario es inválido,
  # el usuario se desuscribió, el teléfono de salida está mal, el usuario no tiene cuenta
  # de WhatsApp.
  PERMANENT_ERROR_CODES = [ 20003, 21211, 21610, 63007, 63024 ].freeze

  queue_as :default

  # Hacer cinco reintentos cubre al rededor de 15 minutos.
  retry_on TransientTwilioError, wait: :polynomially_longer, attempts: 6 do |job, error|
    notification = job.arguments.first

    Rails.logger.error("Reintentos agotados (notification #{notification.id}): #{error.message}")
    notification.update! failed: true
  end

  discard_on PermanentTwilioError do |job, error|
    notification = job.arguments.first

    Rails.logger.error("Fallo (notification #{notification.id}): #{error.message}")
    notification.update! failed: true
  end

  def perform(notification, event_key, title_data, description_data, phone)
    return if Rails.env.development? && ENV["TWILIO_DELIVERY_ENABLED"] != "true"

    return if notification.whatsapp_sent_at.present?

    Rails.logger.info("Enviando notificación (notification #{notification.id})")

    from = ENV.fetch("TWILIO_PHONE")
    content_sid = Notification::Registry.content_sid(event_key)

    # TODO: Borrar esta línea y hacer el chequeo en Notification::Registry cuando todas
    # las notificaciones estén configuradas
    return unless content_sid

    message = client.messages.create(
        from:,
        content_sid:,
        to: "whatsapp:#{phone}",
        content_variables: content_variables(title_data, description_data)
    )

    Rails.logger.info("Enviado mensaje (SID #{message.sid})")

    notification.update! whatsapp_sent_at: Time.current, failed: false
  rescue Twilio::REST::RestError => e
    klass = transient?(e) ? TransientTwilioError : PermanentTwilioError
    raise klass, "#{e.status_code}/#{e.code}: #{e.error_message}"
  rescue Twilio::REST::TwilioError => e
    raise TransientTwilioError, e.message
  end

  private

  # Retorna un hash con todas las claves de ambas entradas, solo que a las claves
  # de title_data se le agrega "title_" al principio, y las de description_data
  # "description_"
  def content_variables(title_data, description_data)
    title_data
      .transform_keys { |key| "title_#{key}" }
      .merge(
        description_data.transform_keys { |key| "description_#{key}" }
      )
      .to_json
  end

  def transient?(error)
    PERMANENT_ERROR_CODES.exclude? error.code
  end

  def client
    Twilio::REST::Client.new(
      ENV.fetch("TWILIO_ACCOUNT_SID"),
      ENV.fetch("TWILIO_AUTH_TOKEN")
    )
  end
end
