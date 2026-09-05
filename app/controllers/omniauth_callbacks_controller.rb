# frozen_string_literal: true

class OmniauthCallbacksController < InertiaController
  skip_before_action :authenticate

  # Rails only requires the CSRF token on unsafe requests (POST/PUT/DELETE).
  # This callback arrives as a GET from Google, so it doesn't apply here.

  def google_oauth2
    user = User.find_or_create_from_google(request.env["omniauth.auth"])
    user.provider || user.create_provider!(email: user.email, username: user.name)

    reset_session
    @session = user.sessions.create!
    cookies.signed.permanent[:session_token] = { value: @session.id, httponly: true }

    redirect_to dashboard_path("provider"), notice: t("flash.signed_in")
  end

  # OmniAuth.config.on_failure redirects here on any failure in the flow
  # (the person cancels the Google consent screen, invalid credentials, etc).
  def failure
    redirect_to sign_in_path, inertia: {
      errors: { auth: t("flash.google_auth_failed") }
    }
  end
end
