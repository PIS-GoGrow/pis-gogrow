# frozen_string_literal: true

class UsersController < InertiaController
  def destroy
    user = Current.user
    if user.authenticate(params[:password_challenge] || "")
      user.destroy!
      Current.session = nil
      redirect_to root_path, notice: t("flash.user_deleted"), inertia: { clear_history: true }
    else
      redirect_to settings_profile_path, inertia: { errors: { password_challenge: t("validations.password_challenge_invalid") } }
    end
  end
end
