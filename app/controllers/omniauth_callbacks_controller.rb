# frozen_string_literal: true

class OmniauthCallbacksController < InertiaController
  skip_before_action :authenticate

  # Rails only requires the CSRF token on unsafe requests (POST/PUT/DELETE).
  # This callback arrives as a GET from Google, so it doesn't apply here.
  def google_oauth2
    user = User.find_from_google(request.env["omniauth.auth"])
    roles = user.roles

    if !user || user.roles.empty?
      # No permitir loguearse si el usuario no existe aún, o si no tiene roles disponibles
      redirect_to sign_in_path, inertia: {
        errors: { auth: t("flash.user_not_found") }
      }

      return
    end

    reset_session

    @session = user.sessions.create! role: roles[0]

    cookies.signed.permanent[:session_token] = { value: @session.id, httponly: true }
    cookies.delete(:accessing_role)

    if roles.length == 1
      redirect_to root_path, notice: t("flash.signed_in")
    else
      redirect_to edit_session_path(@session), notice: t("flash.choose_role")
    end
  rescue User::DomainNotAllowed
    redirect_to sign_in_path, inertia: {
      errors: { auth: t("flash.google_domain_not_allowed") }
    }
  end

  # OmniAuth.config.on_failure redirects here on any failure in the flow
  # (the person cancels the Google consent screen, invalid credentials, etc).
  def failure
    redirect_to sign_in_path, inertia: {
      errors: { auth: t("flash.google_auth_failed") }
    }
  end
end
