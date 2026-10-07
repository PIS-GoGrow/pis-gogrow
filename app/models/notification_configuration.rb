# frozen_string_literal: true

# Representa un conjunto de tipos de notificaciones que son configurables por el
# usuario. La configuración solo se toma en cuenta cuando la notificación se envía
# por WhatsApp. Las configuraciones tienen una clave (key) que las identifica y además
# indican qué roles (consumer, provider, admin) pueden configurarlas.
#
# Un ejemplo de configuración podría ser «Actualización de pedido» con clave
# order_updates, para que el usuario pueda configurar si recibe notificaciones cuando
# se modifica uno de sus pedidos.
#
# El título y la descripción de una configuración no se guarda en la base de datos,
# si no que se configura desde los locales, según la clave. Si creamos una
# NotificationConfiguration con clave :order_updates, es necesario entonces tener
# en es.yml las líneas:
#
#   notification_configurations:
#     order_updates:
#       title: "..."
#       description: "..."
#
# Cada tipo de notificación debe pertenecer a una configuración, por lo que para poder
# crear una notificación, es necesario saber a qué configuración va a pertenecer.
# Entonces, es necesario además crear la configuración a la que va a pertenecer desde
# las seeds.
#
# Cuando un usuario quiere recibir tipos de notificaciones asociadas a una determinada
# configuración, se asocia a la configuración. Si el usuario no tiene un rol presente
# en el atributo roles de la configuración, no puede asociarse.
class NotificationConfiguration < ApplicationRecord
  has_many :user_notification_configurations, dependent: :destroy
  has_many :users, through: :user_notification_configurations, source: :user

  has_many :notifications, dependent: :restrict_with_error
end

# == Schema Information
#
# Table name: notification_configurations
#
#  id         :bigint           not null, primary key
#  key        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_notification_configurations_on_key  (key) UNIQUE
#
