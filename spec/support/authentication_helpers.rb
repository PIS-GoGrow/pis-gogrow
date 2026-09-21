# frozen_string_literal: true

module AuthenticationHelpers
  def self.signed_cookie(name, value)
    cookie_jar = ActionDispatch::Request.new(Rails.application.env_config.deep_dup).cookie_jar
    cookie_jar.signed[name] = value
    cookie_jar[name]
  end

  # sessions.role es NOT NULL, así que hay que derivarlo del perfil del usuario.
  def self.role_for(user)
    return :consumer if user.consumer
    return :provider if user.provider
    return :admin if user.admin

    raise ArgumentError, "Cannot sign in #{user.email}: user has no profile/role assigned"
  end

  module Request
    def sign_in(user, role: nil)
      session = user.sessions.create!(role: role || AuthenticationHelpers.role_for(user))
      cookies[:session_token] = AuthenticationHelpers.signed_cookie(:session_token, session.id)
    end

    def sign_out
      cookies[:session_token] = ""
    end
  end

  module System
    def sign_in(user, role: nil)
      session = user.sessions.create!(role: role || AuthenticationHelpers.role_for(user))
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
