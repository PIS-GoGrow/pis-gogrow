# frozen_string_literal: true

module AuthenticationHelpers
  def self.signed_cookie(name, value)
    cookie_jar = ActionDispatch::Request.new(Rails.application.env_config.deep_dup).cookie_jar
    cookie_jar.signed[name] = value
    cookie_jar[name]
  end

  module Request
    def sign_in(user, role: nil)
      user.sync_roles!
      role = (role || user.roles.first)&.to_sym
      raise ArgumentError, "Cannot sign in #{user.email}: user has no profile/role assigned" unless role

      session = user.sessions.create!(role: role)
      cookies[:session_token] = AuthenticationHelpers.signed_cookie(:session_token, session.id)
    end

    def sign_out
      cookies[:session_token] = ""
    end
  end

  module System
    def sign_in(user, role: nil)
      user.sync_roles!
      role = (role || user.roles.first)&.to_sym
      raise ArgumentError, "Cannot sign in #{user.email}: user has no profile/role assigned" unless role

      session = user.sessions.create!(role: role)
      # El driver de Selenium no tiene set_cookie (eso es de rack_test), y para
      # colgar una cookie el browser necesita estar parado en el dominio: de ahí
      # el visit previo.
      visit "/"
      page.driver.browser.manage.add_cookie(
        name: "session_token",
        value: AuthenticationHelpers.signed_cookie(:session_token, session.id)
      )
    end

    def sign_out
      page.driver.browser.manage.delete_cookie("session_token")
    end
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers::Request, type: :request
  config.include AuthenticationHelpers::System, type: :system
end
