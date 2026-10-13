# frozen_string_literal: true

class Settings::NotificationsController < InertiaController
  before_action :authenticate
  wrap_parameters false

  def index
    @notification_configurations = Notification::Configuration.for_role Current.session.role
    @subscribed_keys =
      @notification_configurations
        .joins(:notification_configuration_users)
        .where(notification_configuration_users: { user_id: Current.user.id })
        .pluck :key
  end

  def update
    config = Notification::Configuration.for_role(Current.session.role).find_by id: config_params[:id]

    if config_params[:subscribe]
      config.users << Current.user
    else
      config.users.destroy Current.user
    end
    
    redirect_to settings_notifications_path, notice: I18n.t("flash.config_update")
  end

  private

  def config_params
    params.permit :subscribe, :id
  end
end
