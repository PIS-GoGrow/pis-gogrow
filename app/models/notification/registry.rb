class Notification::Registry
  PATH = Rails.root.join("config/notifications.yml")

  Configuration = Data.define(:key, :roles)
  Event = Data.define(:key, :configuration_key, :roles, :requires_action)

  class InvalidRegistry < StandardError; end
  class UnknownEvent < StandardError; end

  class << self
    def configurations
      loaded.first
    end

    def events
      loaded.last
    end

    def event?(key)
      events.key?(key.to_s.to_sym)
    end

    def event!(key)
      events.fetch(key.to_sym) { raise UnknownEvent, "Evento desconocido: #{key.inspect}" }
    end

    private

    def loaded
      @loaded ||= build(YAML.safe_load_file(PATH, symbolize_names: true))
    end

    def build(data)
      configurations = data.fetch(:configurations).to_h do |key, attrs|
        [key, Configuration.new(key:, roles: parse_roles(key, attrs.fetch(:roles)))]
      end

      events = data.fetch(:events).to_h do |key, attrs|
        config_key = attrs.fetch(:configuration).to_sym
        config = configurations.fetch(config_key) do
          raise InvalidRegistry, "#{key}: la configuración #{config_key} no existe"
        end
        roles = parse_roles(key, attrs.fetch(:roles))
        if (roles - config.roles).any?
          raise InvalidRegistry, "#{key}: roles #{roles} no incluidos en #{config_key}"
        end

        [key, Event.new(key:, configuration_key: config_key, roles:,
                        requires_action: attrs.fetch(:requires_action))]
      end

      [configurations.freeze, events.freeze]
    end

    def parse_roles(key, roles)
      roles = roles.map(&:to_sym)
      invalid = roles - User::ROLES
      raise InvalidRegistry, "#{key}: roles inválidos #{invalid}" if invalid.any?

      roles.freeze
    end
  end
end