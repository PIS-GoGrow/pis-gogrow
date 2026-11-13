# frozen_string_literal: true

class Consumer::FavoritesController < Consumer::InertiaController
  before_action :set_favoritable

  def update
    Current.user.consumer.favorites.find_or_create_by!(favoritable: @favoritable)
    redirect_back_or_to dashboard_path
  end

  def destroy
    favoritable = @favoritable.is_a?(Menu) ? @favoritable.saved_menu : @favoritable
    Current.user.consumer.favorites.where(favoritable:).destroy_all
    redirect_back_or_to dashboard_path
  end

  private

  def set_favoritable
    @favoritable = Favorite::KINDS.fetch(params[:kind]).constantize.find(params[:id])
  end
end
