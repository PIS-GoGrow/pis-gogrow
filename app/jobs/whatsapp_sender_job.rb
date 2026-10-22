# frozen_string_literal: true

# Envía un mensaje de WhatsApp a un número de celular, dados una clave de evento
# configurada en config/notifications.yml y los datos extra que se necesiten.
# Para que funcione, necesita estar configurada la variable TWILIO_DELIVERY_ENABLED
# en true, y cargadas las credenciales. En producción, la variable TWILIO_DELIVERY_ENABLED
# no se respeta.
class WhatsappSenderJob < ApplicationJob
  queue_as :default

  ACCOUNT_SID_ENV = "TWILIO_ACCOUNT_SID"
  AUTH_TOKEN_ENV = "TWILIO_AUTH_TOKEN"
  FROM_ENV = "TWILIO_PHONE"

  class MissingENV < StandardError; end
  class MissingContentSID < StandardError; end

  def perform(notification, event_key, title_data, description_data, phone, *args)
    return if Rails.env.development? && ENV["TWILIO_DELIVERY_ENABLED"] != "true"

    Rails.logger.info("Enviando notificación de id: #{notification.id}")

    account_sid = ENV.fetch(ACCOUNT_SID_ENV, nil)
    auth_token = ENV.fetch(AUTH_TOKEN_ENV, nil)
    from = ENV.fetch(FROM_ENV, nil)
    content_sid = Notification::Registry.content_sid(event_key)

    raise MissingENV, ACCOUNT_SID_ENV unless account_sid
    raise MissingENV, AUTH_TOKEN_ENV unless auth_token
    raise MissingENV, FROM_ENV unless from
    raise MissingContentSID, event_key unless content_sid

    @client = Twilio::REST::Client.new(account_sid, auth_token)

    message = @client.messages.create(
        from:,
        to: "whatsapp:#{phone}",
        content_sid:,
        content_variables: content_variables(title_data, description_data)
    )

    notification.update! whatsapp_sent_at: Time.now
  rescue MissingENV => e
    Rails.logger.warn("Clave ENV faltante: #{e.message}")
  rescue MissingContentSID => e
    Rails.logger.error("Configuración de content SID faltante en config/notifications.yml para #{e.message}")
  end

  private

  def content_variables(title_data, description_data)
    title_data
      .transform_keys { |key| "title_" + key.to_s }
      .merge(
        description_data
          .transform_keys { |key| "description_" + key.to_s }
      )
      .to_json
  end
end
