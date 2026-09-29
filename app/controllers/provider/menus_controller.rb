# frozen_string_literal: true

class Provider::MenusController < Provider::InertiaController
  def index
    provider = Current.user.provider
    menus = provider.menus.order created_at: :desc

    render inertia: { menus: }
  end

  def new
  end

  def create
    provider = Current.user.provider
    menu = provider.menus.new menu_params

    if menu.save
      redirect_to provider_menus_path
    else
      redirect_to provider_menus_path, inertia: { errors: menu.errors }
    end
  end

  def show
    provider = Current.user.provider
    menu = provider.menus.find(params[:id])

    render inertia: { menu: }
  end

  def edit
    provider = Current.user.provider
    menu = provider.menus.find(params[:id])

    render inertia: { menu: }
  end

  def update
    menu = Current.user.provider.menus.find(params[:id])

    if menu.update(menu_params)
      redirect_to provider_menus_path
    else
      redirect_to edit_provider_menu_path(menu), inertia: { errors: menu.errors }
    end
  end

  def destroy
    provider = Current.user.provider
    menu = provider.menus.find(params[:id])

    if menu.destroy
      redirect_to provider_menus_path
    end
  end

  private

  def menu_params
    params.expect(menu: [
      :name, :price, :description,
      option_groups_attributes: [ [ :id, :name, :limit, :_destroy, options: [] ] ]
    ])
  end
end
