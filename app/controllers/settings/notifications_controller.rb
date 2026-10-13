# frozen_string_literal: true

class Settings::NotificationsController < InertiaController
  before_action :set_user

  def index
    @notification_configurations = Notification::Configuration.for_role Current.session.role
    @subscribed_keys =
      @notification_configurations
        .joins(:notification_configuration_users)
        .where(notification_configuration_users: { user_id: @user.id })
        .pluck :key
  end

  def update
    config = Notification::Configuration.for_role(Current.session.role).find_by id: config_params[:id]

    if config_params[:subscribe]
      config.users << Current.user
    else
      config.users.destroy Current.user
    end

    redirect_to settings_notifications_path, notice: "Cambio persistido"
  end

  private

  def set_user
    @user = Current.user
  end

  def config_params
    params.permit(:id, :subscribe)
  end
end
