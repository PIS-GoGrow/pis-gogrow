# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Favoritos y frecuentes del empleado", type: :request do
  fixtures :users, :consumers, :companies, :providers, :menus, :schedules,
           :benefit_configurations, :benefits, :orders

  let(:user) { users(:one) }
  let(:consumer) { consumers(:one) }
  let(:milanesa) { menus(:milanesa) }
  let(:sorrentinos) { menus(:sorrentinos) }

  before { sign_in(user, role: :consumer) }

  describe "PATCH /favoritos/menus/:id" do
    it "marca un plato como favorito y es idempotente" do
      2.times { patch favorite_path(kind: "menus", id: sorrentinos.id) }

      expect(consumer.favorites.where(favoritable: sorrentinos).count).to eq(1)
    end

    it "guarda el plato original cuando se marca una variante" do
      variant = milanesa.build_variant(valid_from: Date.current, valid_until: Date.current + 7)
      variant.save!

      patch favorite_path(kind: "menus", id: variant.id)

      expect(consumer.favorites.pluck(:favoritable_id)).to eq([ milanesa.id ])
    end

    it "marca un proveedor como favorito" do
      patch favorite_path(kind: "providers", id: providers(:endulzate).id)

      expect(consumer.favorite_ids("Provider")).to eq([ providers(:endulzate).id ])
    end

    it "rechaza un tipo desconocido" do
      patch "/favoritos/users/#{user.id}"

      expect(response).to have_http_status(:not_found)
      expect(consumer.favorites).to be_empty
    end
  end

  describe "DELETE /favoritos/menus/:id" do
    it "quita el favorito" do
      consumer.favorites.create!(favoritable: sorrentinos)

      delete favorite_path(kind: "menus", id: sorrentinos.id)

      expect(consumer.favorites.reload).to be_empty
    end

    it "no toca los favoritos de otro empleado" do
      consumers(:other).favorites.create!(favoritable: sorrentinos)

      delete favorite_path(kind: "menus", id: sorrentinos.id)

      expect(consumers(:other).favorites.count).to eq(1)
    end
  end

  describe "GET /menu-semanal" do
    it "separa los favoritos elegidos de los frecuentes calculados" do
      consumer.favorites.create!(favoritable: sorrentinos)
      consumer.favorites.create!(favoritable: providers(:endulzate))

      get dashboard_path

      expect(inertia).to have_props { |props|
        expect(props[:favorites][:menus].pluck(:id)).to eq([ sorrentinos.id ])
        expect(props[:favorites][:provider_ids]).to eq([ providers(:endulzate).id ])
        expect(props[:frequent][:menus].pluck(:id)).to eq([ milanesa.id ])
        expect(props[:frequent][:provider_ids]).to eq([ providers(:tuviandita).id ])
      }
    end

    it "no cuenta como frecuente un plato con un solo pedido" do
      get dashboard_path

      expect(inertia).to have_props { |props|
        expect(props[:frequent][:menus].pluck(:id)).not_to include(menus(:office_menu).id)
      }
    end

    it "incluye un favorito aunque ninguna fecha de la semana lo programe" do
      consumer.favorites.create!(favoritable: menus(:office_menu))
      Schedule.where(menu: menus(:office_menu)).destroy_all

      get dashboard_path

      expect(inertia).to have_props { |props|
        expect(props[:favorites][:menus].pluck(:id)).to include(menus(:office_menu).id)
        expect(props[:schedules].pluck(:menu).pluck(:saved_menu_id)).not_to include(menus(:office_menu).id)
      }
    end

    it "omite los platos archivados" do
      consumer.favorites.create!(favoritable: sorrentinos)
      sorrentinos.update!(archived_at: Time.current)

      get dashboard_path

      expect(inertia).to have_props { |props| expect(props[:favorites][:menus]).to be_empty }
    end
  end
end
