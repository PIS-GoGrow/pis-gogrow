# frozen_string_literal: true

# Notifier crea una notificación. Una vez creada, no hay que preocuparse por cómo
# se le muestra al usuario o si se envía, esto se hace automáticamente.
#
# Para crearla, es necesario pasarle:
# - qué evento originó la notificación (event_key, que tiene que estar en
#   Notification::EVENT_KEYS);
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
  CONFIG_KEY_MAP = {
    order_confirmed: :order_updates
  }.freeze

  REQUIRES_ACTION = [
    # Deben ser símbolos, por ejemplo: :order_confirmed
  ].to_set.freeze

  def self.call(event_key:, user:, role:, notifiable:, title_data: {}, description_data: {})
    event_key = event_key.to_sym

    configuration_key = CONFIG_KEY_MAP[event_key] || event_key

    # Lanzamos error si la configuration_key es incorrecta
    configuration = NotificationConfiguration.find_by!(key: configuration_key)

    # I18n.t! lanza I18n::MissingTranslationData si falta la traducción, en vez de
    # guardar un texto tipo "translation missing: ..." en la notificación.
    Notification.create!(
      notification_configuration: configuration,
      user:,
      role:,
      event: event_key,
      requires_action: REQUIRES_ACTION.include? event_key,
      notifiable:,
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
