# frozen_string_literal: true

class NotificationsController < InertiaController
  def close
    notification =
      Current.user.notifications
        .active
        .where(role: Current.session.role, requires_action: false)
        .find(params[:id])

    notification.close!

    redirect_back fallback_location: root_path, status: :see_other
  end
end
