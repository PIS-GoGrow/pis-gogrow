# frozen_string_literal: true

class Settings::ProfilesController < InertiaController
  before_action :set_user

  def show
    @provider = Current.session.provider? ? Current.user.provider : nil
  end

  def update
    @provider = Current.user.provider if Current.session.provider?

    if @user.update(user_params) && update_provider
      redirect_to settings_profile_path, notice: t("flash.profile_updated")
    else
      redirect_to settings_profile_path, inertia: { errors: @user.errors }
    end
  end

  private

  def set_user
    @user = Current.user
  end

  def user_params
    params.permit(:name)
  end

  def update_provider
    return true unless @provider && params.key?(:home_delivery)

    @provider.update(home_delivery: params[:home_delivery])
  end
end
