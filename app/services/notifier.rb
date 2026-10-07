# frozen_string_literal: true

# Notifier crea una notificación. Una vez creada, no hay que preocuparse por cómo
# se le muestra al usuario o si se envía, esto se hace automáticamente.
#
# Para crearla, es necesario pasarle:
# - qué evento originó la notificación (event_key);
# - a qué usuario enviarle la notificación (user);
# - a qué rol del usuario mostrarle la notificación (role, que puede ser consumer,
#   admin o provider);
# - qué objeto ocasionó la notificación (notifiable).
#
# El título y descripción de la notificación se generan automáticamente a partir de los
# locales:
# - notifications.{event_key}.title
# - notifications.{event_key}.description
# que deben existir.
#
# Además, se tiene que definir en esta clase a qué configuración corresponde un
# determinado evento, por ejemplo: el evento «Confirmación de pedido» corresponde
# a la configuración «Actualización de pedido». Esto se hace en CONFIG_KEY_MAP.
# Si el evento tiene la misma clave que la configuración, no es necesario definir nada.
# Más información sobre las configuraciones en NotificationConfiguration.
#
# También se tiene que definir para cada evento si se requiere una acción con él
# o no. Requerir una acción implica que la notificación es persistente (aparece como
# rojo en el figma). Si un evento requiere acción, hay que agregar la clave de ese
# evento al arreglo REQUIRES_ACTION.
#
# El objeto notifiable conceptualmente debería representar el objeto responsable de que
# se le esté enviando una notificación al usuario. Además, si la notificación requiere
# acción, entonces la acción tendría que hacerse sobre el objeto notifiable.
# Por ejemplo:
# - Si el evento es que se confirmó un pedido, notifiable es ese pedido
# - Si el evento es que hay pagos pendientes, notifiable es la cuenta en la que hay un
#   pago pendiente.
# Para tener en cuenta, para un mismo evento, usuario y notifiable, puede haber una
# única notificación. Entonces, un notifiable no debe poder generar varias
# notificaciones a un mismo usuario en el mismo evento.
#
# Una vez creada la notificación, si requiere acción la podemos cerrar cuando el usuario
# haga la acción con el método Notification.close_by!, que acepta una clave de evento,
# el objeto notifiable y el usuario.
class Notifier
  class MissingConfiguration < StandardError; end

  def self.call(event_key:, user:, notifiable:, title_data: {}, description_data: {})
    event = Notification::Registry.event!(event_key)

    # Buscamos la Notification::Configuration correspondiente a ese evento
    configuration = find_configuration_for! event
    
    # I18n.t! lanza I18n::MissingTranslationData si falta la traducción, en vez de
    # guardar un texto tipo "translation missing: ..." en la notificación.
    Notification.create!(
      notification_configuration: configuration,
      user:,
      role: event.role,
      event: event.key,
      requires_action: event.requires_action,
      notifiable:,
      title: I18n.t!("notifications.#{event.key}.title", **title_data),
      description: I18n.t!("notifications.#{event.key}.description", **description_data)
    )
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
    Notification::Configuration.find_by(key: event.configuration_key.to_s + " sa") || raise(
      MissingConfiguration,
      "Se trató crear una notificación incorrectamente: " \
      "No existe la configuración '#{event.configuration_key}' (evento '#{event.key}'). " \
      "Probá corriendo 'rails notifications:sync' o corrigiendo config/notifications.yml."
    )
  end
end
