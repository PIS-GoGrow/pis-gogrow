# frozen_string_literal: true

# Autoriza, por unos minutos y solo en esta sesión, a elegir una contraseña
# nueva después de haber probado que se controla el correo (código o invitación).
module PasswordGrant
  extend ActiveSupport::Concern

  private

  def grant_password_change(user, purpose)
    session[:password_grant] = { "user_id" => user.id, "purpose" => purpose.to_s, "expires_at" => 15.minutes.from_now.to_i }
  end

  def granted_user(purpose)
    grant = session[:password_grant]
    return unless grant && grant["purpose"] == purpose.to_s && grant["expires_at"] > Time.current.to_i

    User.find_by(id: grant["user_id"])
  end

  def clear_password_grant
    session.delete(:password_grant)
  end
end
