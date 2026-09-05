# frozen_string_literal: true

# Hardcodear id del proveedor mientras no haya login
PROVIDER_ID = 1

class MenusController < ApplicationController
  skip_before_action :authenticate

  def index
    provider = Provider.find PROVIDER_ID
    menus = provider.menus

    render inertia: { menus: }
  end

  def new
  end

  def create
    provider = Provider.find PROVIDER_ID
    menu = provider.menus.new menu_params

    if menu.save
      redirect_to menus_path
    else
      render inertia: "menus/new", props: { errors: @menu.errors }
    end
  end

  def show
    provider = Provider.find PROVIDER_ID
    menu = provider.menus.find(params[:id])

    render inertia: { menu: }
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

  def menu_params
    params.expect(menu: [:name, :price, :description])
  end
end
