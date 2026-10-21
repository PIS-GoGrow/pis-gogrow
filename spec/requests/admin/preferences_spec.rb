# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Admin::Preferences", type: :request do
  fixtures :users

  describe "GET /admin/preferencias" do
    it "redirects visitors without a session to sign in" do
      get admin_preferences_path

      expect(response).to redirect_to(sign_in_path)
    end

    it "rejects sessions from another role" do
      sign_in users(:one), role: :consumer

      get admin_preferences_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("flash.no_permission"))
    end

    it "renders profile and appearance preferences for RRHH" do
      sign_in users(:admin), role: :admin

      get admin_preferences_path

      expect(response).to have_http_status(:ok)
      expect(inertia).to render_component("admin/preferences/show")
    end
  end
end
