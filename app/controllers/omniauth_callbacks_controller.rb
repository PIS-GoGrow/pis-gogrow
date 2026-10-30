# frozen_string_literal: true

class OmniauthCallbacksController < InertiaController
  skip_before_action :authenticate

  # Rails only requires the CSRF token on unsafe requests (POST/PUT/DELETE).
  # This callback arrives as a GET from Google, so it doesn't apply here.
  def google_oauth2
    user = User.find_from_google(request.env["omniauth.auth"])

    # Asegurarse de que los roles del usuario están bien calculados
    user&.sync_roles!

    if !user || user.roles.empty?
      # No permitir loguearse si el usuario no existe aún, o si no tiene roles disponibles
      redirect_to entry_path, inertia: {
        errors: { auth: t("flash.user_not_found") }
      }

      return
    end

    entry_role = Session::ENTRY_ROLES[origin_path]

    if entry_role && user.roles.exclude?(entry_role)
      redirect_to entry_path, inertia: {
        errors: { auth: t("flash.role_not_available") }
      }

      return
    end

    reset_session

    @session = user.sessions.create! role: entry_role || user.roles[0]

    cookies.signed.permanent[:session_token] = { value: @session.id, httponly: true }
    cookies.delete(:accessing_role)

    if entry_role || user.roles.length == 1
      redirect_to root_path, notice: t("flash.signed_in")
    else
      redirect_to edit_session_path(@session), notice: t("flash.signed_in")
    end
  rescue User::DomainNotAllowed
    redirect_to entry_path, inertia: {
      errors: { auth: t("flash.google_domain_not_allowed") }
    }
  end

  # OmniAuth.config.on_failure redirects here on any failure in the flow
  # (the person cancels the Google consent screen, invalid credentials, etc).
  def failure
    redirect_to entry_path, inertia: {
      errors: { auth: t("flash.google_auth_failed") }
    }
  end

  private

  def origin_path
    URI(request.env["omniauth.origin"].to_s).path
  rescue URI::InvalidURIError
    nil
  end

  def entry_path
    Session::ENTRY_ROLES.key?(origin_path) ? origin_path : consumer_welcome_path
  end
end
