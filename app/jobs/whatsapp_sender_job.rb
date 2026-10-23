# frozen_string_literal: true

# Envía un mensaje de WhatsApp a un número de celular, dados una clave de evento
# configurada en config/notifications.yml y los datos extra que se necesiten.
# Para que funcione, necesitan estar cargadas las credenciales. En development,
# solo corre cuando esta configurado.
# Cuando hay un error de red, se reintenta hasta cinco veces el envío. Si los cinco
# intentos fallan, se marca la notificación con el atrbuto failed.
# Si el Job fue exitoso, marca la notifiación como no failed y registra la hora de
# envío
# Este Job no debería ser accedido desde ningún lugar, menos el servicio Notifier.
# Supone que Notifier ya chequeó que la clave de evento exista.
class WhatsappSenderJob < ApplicationJob
  class TransientTwilioError < StandardError; end
  class PermanentTwilioError < StandardError; end

  queue_as :default

  # Hacer cinco reintentos cubre al rededor de 15 minutos.
  retry_on TransientTwilioError, wait: :polynomially_longer, attempts: 6 do |job, error|
    notification = job.arguments.first

    Rails.logger.error("Reintentos agotados (notification #{notification.id}): #{error.message}")
    notification.update! failed: true
  end

  # No reintentamos si: hay un error de autenticación, el número del usuario es inválido,
  # el usuario se desuscribió, el teléfono de salida está mal, el usuario no tiene cuenta
  # de WhatsApp.
  PERMANENT_ERRROR_CODES = [20003, 21211, 21610, 63007, 63024].freeze

  discard_on PermanentTwilioError do |job, error|
    Rails.logger.error("Fallo (notification #{job.arguments.first.id}): #{error.message}")
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
    PERMANENT_ERRROR_CODES.exclude? error.code
  end

  def client
    Twilio::REST::Client.new(
      ENV.fetch("TWILIO_ACCOUNT_SID"),
      ENV.fetch("TWILIO_AUTH_TOKEN")
    )
  end
end
