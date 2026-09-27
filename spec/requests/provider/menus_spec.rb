# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Provider::Menus", type: :request do
  fixtures :users, :providers, :menus, :consumers

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

    it "creates a new dish with valid parameters and redirects to the index" do
      expect do
        post provider_menus_path, params: {
          menu: {
            name: "Suprema napolitana",
            price: 360.0,
            description: "Con guarnición a elección",
            fillings: [ "Jamón", "Queso" ],
            sauces: [ "Tuco" ]
          }
        }
      end.to change(provider.menus, :count).by(1)

      expect(response).to redirect_to(provider_menus_path)
      created = provider.menus.order(:id).last
      expect(created.name).to eq("Suprema napolitana")
      expect(created.price).to eq(360.0)
      expect(created.description).to eq("Con guarnición a elección")
      expect(created.fillings).to eq([ "Jamón", "Queso" ])
      expect(created.sauces).to eq([ "Tuco" ])
    end

    it "creates a dish without optional description and toppings" do
      expect do
        post provider_menus_path, params: {
          menu: {
            name: "Ensalada César",
            price: 290.0,
            description: nil
          }
        }
      end.to change(provider.menus, :count).by(1)

      expect(response).to redirect_to(provider_menus_path)
      created = provider.menus.order(:id).last
      expect(created.name).to eq("Ensalada César")
      expect(created.description).to be_nil
      expect(created.fillings).to eq([])
      expect(created.sauces).to eq([])
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

  describe "DELETE /provider/menus/:id" do
    before { sign_in provider_user, role: :provider }

    it "deletes the dish and redirects to index" do
      menu_to_delete = provider.menus.create!(name: "Pastel de carne", price: 280)

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
