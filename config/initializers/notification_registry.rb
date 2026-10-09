# frozen_string_literal: true

# Para que un config/notifications.yml nunca quede mal, al cargar la aplicación
# intentamos acceder a él para que tire error en ese caso.
# Si esto tira error, es porque config/notifications.yml está mal.
Rails.application.config.after_initialize do
  Notification::Registry.events
end
