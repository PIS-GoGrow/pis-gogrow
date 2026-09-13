# frozen_string_literal: true

class Consumer::MenusController < Consumer::InertiaController
  def index
    @menus = available_menus.order("schedules.date", :name)
  end

  def show
    @menu = available_menus.find(params[:id])
  end

  private

  def available_menus
    Menu.includes(:schedules, provider: :user).merge(Schedule.available).references(:schedules)
  end
end
