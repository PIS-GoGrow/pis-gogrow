# frozen_string_literal: true

require "rails_helper"
require "inertia_rails/rspec"

RSpec.describe "Admin::Accounts", type: :request do
  fixtures :users, :companies, :admins, :providers, :consumers

  describe "GET /admin/cuenta" do
    it "redirects visitors without a session to sign in" do
      get admin_account_path

      expect(response).to redirect_to(admin_welcome_path)
    end

    it "rejects sessions from another role" do
      sign_in users(:one), role: :consumer

      get admin_account_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("flash.no_permission"))
    end

    it "renders the account page for RRHH with the authenticated user" do
      admin = users(:admin)
      sign_in admin, role: :admin

      get admin_account_path

      expect(response).to have_http_status(:ok)
      expect(inertia).to render_component("admin/accounts/show")
      expect(inertia).to have_props { |props| props.dig(:auth, :user).values_at(:id, :name, :email) == [ admin.id, admin.name, admin.email ] }
    end
  end
end
