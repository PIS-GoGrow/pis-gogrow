# frozen_string_literal: true

class Consumer::MenusController < Consumer::InertiaController
  def index
    date = params[:date].present? ? Date.parse(params[:date]) : Date.today
    @schedules = Schedule.where(date:).includes(menu: { provider: :user })
    @providers = Provider.includes(:user).all
    @date = date.to_s
  end
end
