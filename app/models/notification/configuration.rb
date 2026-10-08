# frozen_string_literal: true

# Representa un conjunto de tipos de notificaciones que son configurables por el
# usuario. La configuración solo se toma en cuenta cuando la notificación se envía
# por WhatsApp, todas las notificaciones aparecen siempre en la app. Las
# configuraciones tienen una clave (key) que las identifica y además indican qué roles
# (consumer, provider, admin) pueden configurarlas.
#
# Cada tipo de notificación debe pertenecer a una configuración, por lo que para poder
# crear una notificación, es necesario saber a qué configuración va a pertenecer.
# Las configuraciones en principio son las que aparecen en la pantalla de configurar
# notificaciones en el Figma para cada rol. Además, hay que saber desde qué roles
# se puede acceder a una configuración. Desde config/notifications.yml se configuran
# las configuraciones posibles, así como los roles que pueden acceder a ellos. 
#
# Un ejemplo de configuración podría ser «Actualización de pedido» con clave
# order_updates, para que el usuario pueda configurar si recibe notificaciones cuando
# se modifica uno de sus pedidos. Además, dentro de esa configuración podría encontrarse
# el evento «Confirmación de pedido» y «Cancelación de pedido». El usuario configura
# ambos a la vez como «Actualización de pedido», pero en realidad son tipos separados.
# Esta configuración solo aplica a consumidores, por lo que tiene roles [consumer].
#
# El título y la descripción de una configuración no se guarda en la base de datos,
# sino que se configura desde los locales, según la clave. Si creamos una
# Notification::Configuration con clave :order_updates, es necesario entonces tener
# en es.yml las líneas:
#
#   notification_configurations:
#     order_updates:
#       title: "..."
#       description: "..."
#
# Cuando un usuario quiere recibir tipos de notificaciones asociadas a una determinada
# configuración, se asocia a la configuración. Si el usuario no tiene un rol presente
# en el atributo roles de la configuración, no puede asociarse.
class Notification::Configuration < ApplicationRecord
  has_many :notification_configuration_users,
           dependent: :destroy,
           class_name: "Notification::ConfigurationUser"
  has_many :users, through: :notification_configuration_users, source: :user

  has_many :notifications, dependent: :restrict_with_error

  # Crea las configuraciones según lo que dice Notification::Registry.
  # Nunca borra configuraciones, las reporta para elegir qué hacer, pero sí
  # cambia los roles de la configuración según los cambios de Notification::Registry.
  def self.sync!
    keys = Notification::Registry.configurations.keys.map(&:to_s)

    transaction do
      Notification::Registry.configurations.each_value do |config|
        find_or_initialize_by(key: config.key.to_s)
          .update!(roles: config.roles.map(&:to_s))
      end
    end

    orphans = where.not(key: keys).pluck(:key)
    if orphans.any?
      Rails.logger.warn("[Notification::Configuration] Claves huérfanas: #{orphans}")
      Rails.logger.warn("[Notification::Configuration] Habría que eliminarlas si no son necesarias o revisar la configuración de config/notifications.yml")
      orphans
    end
  end
end

# == Schema Information
#
# Table name: notification_configurations
#
#  id         :bigint           not null, primary key
#  key        :string           not null
#  roles      :string           default([]), is an Array
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_notification_configurations_on_key  (key) UNIQUE
#
