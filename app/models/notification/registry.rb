# frozen_string_literal: true

# Es la interfaz al archivo config/notifications.yml.
# Se encarga de cargar este archivo y determinar los eventos y configuraciones que
# ahí se definieron para poder ser usados en el resto del código.
class Notification::Registry
  PATH = Rails.root.join("config/notifications.yml")

  Configuration = Data.define(:key, :roles)
  Event = Data.define(:key, :configuration_key, :role, :requires_action)

  class InvalidRegistry < StandardError; end
  class UnknownEvent < StandardError; end

  class << self
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
        [ key, Configuration.new(key:, roles: parse_roles(key, attrs.fetch(:roles))) ]
      end

      events = data.fetch(:events).to_h do |key, attrs|
        configuration_key = attrs.fetch(:configuration).to_sym
        config = configurations.fetch(configuration_key) do
          raise InvalidRegistry, "#{key}: la configuración #{configuration_key} no existe"
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
