# frozen_string_literal: true

require "socket"

module Ibp041
  module LocalDatabaseGuard
    def self.allowed?
      return false unless Rails.env.development?
      return false unless ENV["IBP041_QA_LOCAL_DB"] == "rails_inertia_base_development@db"
      return false if ENV["DATABASE_URL"].present? || ENV["PGHOST"] != "db"
      return false if ENV["PGPORT"].present? && ENV["PGPORT"] != "5432"
      return false unless ActiveRecord::Base.connection_db_config.database == "rails_inertia_base_development"

      connection = ActiveRecord::Base.connection
      return false unless connection.select_value("SELECT current_database()") == "rails_inertia_base_development"
      return false unless connection.select_value("SELECT inet_server_port()").to_i == 5432

      Addrinfo.getaddrinfo("db", 5432, :INET, :STREAM).map(&:ip_address)
              .include?(connection.select_value("SELECT host(inet_server_addr())"))
    rescue SocketError, ActiveRecord::ConnectionNotEstablished
      false
    end
  end
end
