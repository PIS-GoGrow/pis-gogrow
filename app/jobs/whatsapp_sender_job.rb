# frozen_string_literal: true

# Envía un mensaje de WhatsApp a un número de celular.
# Este Job no debería ser accedido desde ningún lugar, menos el servicio Notifier.
# Ver más documentación en docs/notificaciones.md
class WhatsappSenderJob < ApplicationJob
  # Errores que se reintentan y que no
  class TransientTwilioError < StandardError; end
  class PermanentTwilioError < StandardError; end

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

  def perform(notification)
    return if Rails.env.development? && ENV["TWILIO_DELIVERY_ENABLED"] != "true"

    return if notification.whatsapp_sent_at.present? && !notification.failed

    Rails.logger.info("Enviando notificación (notification #{notification.id})")

    from = ENV.fetch("TWILIO_PHONE")
    content_sid = Notification::Registry.content_sid(notification.event, count: notification.description_data["count"].to_i)
    status_callback = ENV.fetch("TWILIO_STATUS_CALLBACK_URL", nil) || Rails.application.routes.url_helpers.twilio_callback_url

    message = client.messages.create(
      from:,
      content_sid:,
      to: "whatsapp:#{notification.user.phone}",
      content_variables: content_variables(notification.title_data, notification.description_data),
      status_callback:
    )

    Rails.logger.info("Enviado mensaje (SID #{message.sid})")

    notification.update!(
      whatsapp_sent_at: Time.current,
      failed: false,
      twilio_sid: message.sid,
      send_attempts: notification.send_attempts + 1
    )
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
      .transform_values(&:to_s)
      .to_json
  end

  # Un 4xx (salvo 429) no va a cambiar al reintentar: credenciales, número o variables
  # inválidas.
  def transient?(error)
    error.status_code == 429 || error.status_code >= 500
  end

  def client
    Twilio::REST::Client.new(
      ENV.fetch("TWILIO_ACCOUNT_SID"),
      ENV.fetch("TWILIO_AUTH_TOKEN")
    )
  end
end
