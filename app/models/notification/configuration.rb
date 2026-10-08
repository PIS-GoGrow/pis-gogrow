# frozen_string_literal: true

# Representa un conjunto de tipos de notificaciones que son configurables por el
# usuario. La configuración solo se toma en cuenta cuando la notificación se envía
# por WhatsApp, todas las notificaciones aparecen siempre en la app. Las
# configuraciones tienen una clave (key) que las identifica y además indican qué roles
# (consumer, provider, admin) pueden configurarlas.
#
# Ver más documentación en docs/notificaciones.rb
class Notification::Configuration < ApplicationRecord
  has_many :notification_configuration_users,
           dependent: :destroy,
           foreign_key: :notification_configuration,
           class_name: "Notification::ConfigurationUser"
  has_many :users, through: :notification_configuration_users, source: :user

  has_many :notifications,
           dependent: :restrict_with_error,
           foreign_key: :notification_configuration

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
