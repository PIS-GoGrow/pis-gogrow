# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Consumer::Menus", type: :request do
  fixtures :users, :companies, :consumers, :providers, :menus, :schedules

  describe "GET /menus" do
    it "redirects to sign in without a session" do
      get menus_path

      expect(response).to redirect_to(sign_in_path)
    end

    it "rejects a session with another role" do
      sign_in users(:two), role: :provider

      get menus_path

      expect(response).to redirect_to(sign_in_path)
    end

    context "as a consumer" do
      before { sign_in users(:one), role: :consumer }

      it "lists menus with upcoming dates and spots left, soonest first" do
        get menus_path

        expect(inertia).to render_component("consumer/menus/index")
        expect(inertia).to have_props { |props|
          props[:menus].pluck(:name) == [ "Milanesa con papas fritas", "Empanadas de carne" ]
        }
      end

      it "includes only the available dates of each menu" do
        get menus_path

        expect(inertia).to have_props { |props|
          empanadas = props[:menus].find { it[:name] == "Empanadas de carne" }
          empanadas[:provider_name] == users(:two).name &&
            empanadas[:schedules].pluck(:date) == [ Date.current.tomorrow.iso8601 ]
        }
      end
    end
  end

  describe "GET /menus/:id" do
    before { sign_in users(:one), role: :consumer }

    it "shows an available menu" do
      get menu_path(menus(:milanesa))

      expect(inertia).to render_component("consumer/menus/show")
      expect(inertia).to have_props { |props|
        props.dig(:menu, :name) == "Milanesa con papas fritas" && props.dig(:menu, :price) == "300.0"
      }
    end

    it "returns not found for a menu without available dates" do
      get menu_path(menus(:guiso))

      expect(response).to have_http_status(:not_found)
    end
  end
end
