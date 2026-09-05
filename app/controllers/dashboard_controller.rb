# frozen_string_literal: true

class DashboardController < InertiaController
  # /dashboard renders the same generic placeholder it always has. Only
  # /dashboard/:role gates access — it checks that Current.user actually has
  # the profile (Admin/Consumer/Provider) that role names before rendering.
  def index
    @role = params[:role]
    return unless @role

    unless Current.user.public_send(@role)
      redirect_to dashboard_path and return
    end
  end
end
