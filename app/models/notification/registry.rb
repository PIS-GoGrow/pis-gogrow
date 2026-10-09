# frozen_string_literal: true

# Es la interfaz al archivo config/notifications.yml.
# Se encarga de cargar este archivo y determinar los eventos y configuraciones que
# ahí se definieron para poder ser usados en el resto del código.
class Notification::Registry
  PATH = Rails.root.join("config/notifications.yml")

  Configuration = Data.define(:key, :roles, :configurable)
  Event = Data.define(:key, :configuration_key, :role, :requires_action)

  class InvalidRegistry < StandardError; end
  class UnknownEvent < StandardError; end

  class << self
    # data tiene que ser un arreglo con:
    # - en el primer elemento un hash con claves de configuración que llevan
    #   a elementos Configuration
    # - en el segundo un hash con claves de evento que llevan a elementos Event.
    # Usar esta función es un error fuera del ambiente de testing: solo se debería
    # usar para probar comportamientos del Registry.
    def set_data(data)
      unless Rails.env.test?
        raise NotImplementedError, "Notification::Registry.set_data solo se puede usar en testing"
      end

      @loaded = data
    end

    def configurations
      loaded.first
    end

    def events
      loaded.last
    end

    # Devuelve si la clave dada está definida como evento
    def event?(key)
      events.key?(key.to_s.to_sym)
    end

    # Devuelve la información asociada al evento de la clave que se pasó.
    # Tira error si la clave no está definida.
    def event!(key)
      events.fetch(key.to_sym) { raise UnknownEvent, "Evento desconocido: #{key.inspect}" }
    end

    private

    # Carga el archivo
    def loaded
      @loaded ||= build(YAML.safe_load_file(PATH, symbolize_names: true))
    end

    # Construye la representación a partir del archivo
    def build(data)
      configurations = data.fetch(:configurations).to_h do |key, attrs|
        [
          key,
          Configuration.new(
            roles: parse_roles(key, attrs.fetch(:roles)),
            configurable: attrs.fetch(:configurable),
            key:
          )
        ]
      end

      events = data.fetch(:events).to_h do |key, attrs|
        configuration_key = attrs.fetch(:configuration).to_sym
        config = configurations.fetch(configuration_key) do
          raise(
            InvalidRegistry,
            "la configuración #{configuration_key} no existe, " \
            "pero se uso en el evento #{key} en el archivo config/notifications.yml. " \
            "Hay que agregar la configuración en el mismo archivo o cambiar el evento."
          )
        end

        role = parse_roles(key, [ attrs.fetch(:role) ])[0]
        unless config.roles.include? role
          raise InvalidRegistry, "#{key}: rol #{role} no incluido en #{configuration_key}"
        end

        requires_action = attrs.fetch(:requires_action)

        [ key, Event.new(key:, configuration_key:, role:, requires_action:) ]
      end

      [ configurations.freeze, events.freeze ]
    end

    def parse_roles(key, roles)
      roles = roles.map(&:to_sym)
      invalid = roles - User::ROLES
      raise InvalidRegistry, "#{key}: roles inválidos #{invalid}" if invalid.any?

      roles.freeze
    end
  end
end
