# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Provider::Menus", type: :request do
  fixtures :users, :providers, :menus, :consumers, :menu_option_groups

  let(:provider_user) { users(:provider_user) }
  let(:provider) { providers(:tuviandita) }
  let(:other_provider_user) { users(:other_provider_user) }
  let(:other_provider) { providers(:endulzate) }

  describe "GET /provider/menus" do
    it "redirects visitors without a session to the sign in page" do
      get provider_menus_path

      expect(response).to redirect_to(sign_in_path)
    end

    it "redirects consumers to the root page" do
      sign_in users(:one), role: :consumer

      get provider_menus_path

      expect(response).to redirect_to(root_path)
    end

    it "lists the menus of the signed-in provider in descending creation order" do
      sign_in provider_user, role: :provider

      get provider_menus_path

      expect(response).to have_http_status(:success)
      expect(inertia).to render_component("provider/menus/index")

      listed_menus = inertia.props[:menus]
      expect(listed_menus.map { |m| m["id"] }).to include(menus(:milanesa).id)
      expect(listed_menus.map { |m| m["id"] }).not_to include(menus(:sorrentinos).id)
    end
  end

  describe "POST /provider/menus" do
    before { sign_in provider_user, role: :provider }

    it "creates a new dish with option groups and redirects to the index" do
      expect do
        post provider_menus_path, params: {
          menu: {
            name: "Suprema napolitana",
            price: 360.0,
            description: "Con guarnición a elección",
            option_groups_attributes: [
              { name: "Salsa", options: [ "Tuco", "Caruso" ], limit: 1 },
              { name: "Guarnición", options: [ "Papas fritas", "Ensalada" ], limit: 1 }
            ]
          }
        }
      end.to change(provider.menus, :count).by(1)

      expect(response).to redirect_to(provider_menus_path)
      created = provider.menus.order(:id).last
      expect(created.name).to eq("Suprema napolitana")
      expect(created.option_groups.count).to eq(2)
      expect(created.option_groups.find_by(name: "Salsa").options).to eq([ "Tuco", "Caruso" ])
    end

    it "creates a dish without option groups" do
      expect do
        post provider_menus_path, params: {
          menu: {
            name: "Ensalada César",
            description: "Ensalada con pollo, lechuga y aderezo César",
            price: 290.0
          }
        }
      end.to change(provider.menus, :count).by(1)

      expect(response).to redirect_to(provider_menus_path)
      expect(provider.menus.order(:id).last.option_groups).to be_empty
    end

    it "rejects a dish with duplicate options in a group" do
      expect do
        post provider_menus_path, params: {
          menu: {
            name: "Plato",
            price: 300.0,
            option_groups_attributes: [ { name: "Salsa", options: [ "Tuco", "Tuco" ], limit: 1 } ]
          }
        }
      end.not_to change(Menu, :count)

      expect(response).to redirect_to(provider_menus_path)
      follow_redirect!
      expect(inertia.props[:errors]).to have_key(:"option_groups.options")
    end

    it "rejects a dish without a name and returns validation errors" do
      expect do
        post provider_menus_path, params: {
          menu: {
            name: "",
            price: 300.0
          }
        }
      end.not_to change(Menu, :count)

      expect(response).to redirect_to(provider_menus_path)
      follow_redirect!
      expect(inertia.props[:errors]).to have_key(:name)
    end

    it "rejects a dish with non-positive price" do
      expect do
        post provider_menus_path, params: {
          menu: {
            name: "Plato inválido",
            price: 0
          }
        }
      end.not_to change(Menu, :count)

      expect(response).to redirect_to(provider_menus_path)
      follow_redirect!
      expect(inertia.props[:errors]).to have_key(:price)
    end
  end

  describe "GET /provider/menus/:id" do
    before { sign_in provider_user, role: :provider }

    it "renders the dish detail for the provider's own dish" do
      get provider_menu_path(menus(:milanesa))

      expect(response).to have_http_status(:success)
      expect(inertia).to render_component("provider/menus/show")
      expect(inertia.props[:menu]["name"]).to eq("Milanesa con papas fritas")
    end

    it "returns not found when attempting to view another provider's dish" do
      get provider_menu_path(menus(:sorrentinos))

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /provider/menus/:id/edit" do
    before { sign_in provider_user, role: :provider }

    it "renders the edit page for the provider's own dish" do
      menu = menus(:milanesa)

      get edit_provider_menu_path(menu)

      expect(response).to have_http_status(:success)
      expect(inertia).to render_component("provider/menus/edit")
      expect(inertia.props[:menu]["id"]).to eq(menu.id)
      expect(inertia.props[:menu]["name"]).to eq(menu.name)
      expect(inertia.props[:menu]).to have_key("option_groups")
    end

    it "returns not found when attempting to edit another provider's dish" do
      get edit_provider_menu_path(menus(:sorrentinos))

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /provider/menus/:id" do
    before { sign_in provider_user, role: :provider }

    it "updates option groups of an existing dish" do
      menu = menus(:milanesa)
      group = menu.option_groups.create!(name: "Salsa", options: [ "Tuco" ], limit: 1)

      patch provider_menu_path(menu), params: {
        menu: {
          option_groups_attributes: [ { id: group.id, name: "Salsa", options: [ "Tuco", "Caruso" ], limit: 2 } ]
        }
      }

      expect(response).to redirect_to(edit_provider_menu_path(menu))
      expect(group.reload.options).to eq([ "Tuco", "Caruso" ])
      expect(group.reload.limit).to eq(2)
    end

    it "updates the provider's dish information" do
      menu = menus(:milanesa)

      patch provider_menu_path(menu), params: {
        menu: {
          name: "Milanesa napolitana",
          description: "Con papas fritas",
          price: 420.50
        }
      }

      expect(response).to redirect_to(edit_provider_menu_path(menu))

      menu.reload
      expect(menu.name).to eq("Milanesa napolitana")
      expect(menu.description).to eq("Con papas fritas")
      expect(menu.price).to eq(420.50)
    end

    it "returns validation errors when the changes are invalid" do
      menu = menus(:milanesa)

      patch provider_menu_path(menu), params: {
        menu: {
          name: "",
          description: "",
          price: 0
        }
      }

      expect(response).to redirect_to(edit_provider_menu_path(menu))

      follow_redirect!
      expect(inertia.props[:errors]).to have_key(:name)
      expect(inertia.props[:errors]).to have_key(:price)
      expect(inertia.props[:errors]).to have_key(:description)
    end

    it "returns not found when attempting to update another provider's dish" do
      menu = menus(:sorrentinos)
      original_name = menu.name

      patch provider_menu_path(menu), params: {
        menu: {
          name: "No debería cambiar",
          price: 999
        }
      }

      expect(response).to have_http_status(:not_found)
      expect(menu.reload.name).to eq(original_name)
    end

    it "removes an option group with _destroy" do
      menu = menus(:milanesa)
      group = menu.option_groups.create!(name: "Salsa", options: [ "Tuco" ], limit: 1)

      expect do
        patch provider_menu_path(menu), params: {
          menu: {
            option_groups_attributes: [ { id: group.id, _destroy: true } ]
          }
        }
      end.to change(MenuOptionGroup, :count).by(-1)

      expect(response).to redirect_to(edit_provider_menu_path(menu))
    end
  end

  describe "DELETE /provider/menus/:id" do
    before { sign_in provider_user, role: :provider }

    it "deletes the dish and redirects to index" do
      menu_to_delete = provider.menus.create!(
        name: "Pastel de carne",
        description: "Pastel de carne con puré",
        price: 280
      )

      expect do
        delete provider_menu_path(menu_to_delete)
      end.to change(provider.menus, :count).by(-1)

      expect(response).to redirect_to(provider_menus_path)
    end

    it "returns not found when attempting to delete another provider's dish" do
      expect do
        delete provider_menu_path(menus(:sorrentinos))
      end.not_to change(Menu, :count)

      expect(response).to have_http_status(:not_found)
    end
  end
end
